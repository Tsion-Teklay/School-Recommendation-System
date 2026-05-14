import { db } from "../config/db.js";
import {
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";

// ✅ Create School
export async function createSchool(data, userId) {
  const {
    schoolName,
    address,
    contactEmail,
    contactPhone,
    curriculum,
    schoolLevel,
    tuitionFee,
    facilities,
    latitude,
    longitude,
  } = data;

  // Basic validation (also enforced at route level via Zod)
  if (
    !schoolName ||
    !address ||
    !contactEmail ||
    !curriculum ||
    tuitionFee === undefined
  ) {
    throw new ValidationError("Missing required fields");
  }

  const school = await db.school.create({
    data: {
      schoolName,
      address,
      contactEmail,
      contactPhone,
      curriculum,
      // Phase 11 — optional education level; omitted keeps the column null.
      ...(schoolLevel ? { schoolLevel } : {}),
      tuitionFee,
      facilities,
      latitude,
      longitude,
      adminId: userId, // 🔑 link to logged-in admin
      verificationStatus: "PENDING",
    },
  });

  return school;
}

/**
 * Phase 4 — Haversine helpers for proximity search.
 *
 * MariaDB has spatial types but the existing schema stores latitude/longitude
 * as DECIMAL(9,6). Adding a geometry column + spatial index just for one
 * filter would be overkill at this stage, so we:
 *
 *   1. Pre-filter at the DB with a bounding box (cheap, indexable on simple
 *      lat/lng range scans) so we don't pull every school into Node.
 *   2. Compute the exact great-circle distance in JS for the survivors and
 *      drop the ones outside `radiusKm`.
 *
 * For a ~few-thousand-row catalog this is fast enough; if the dataset grows
 * past that we'd revisit with a real spatial index.
 */
const EARTH_RADIUS_KM = 6371;
function toRad(deg) {
  return (deg * Math.PI) / 180;
}
function haversineKm(lat1, lng1, lat2, lng2) {
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a));
}

// ✅ Get All Schools (PUBLIC)
export async function getAllSchools(query) {
  const {
    adminId,
    search,
    curriculum,
    schoolLevel,
    minFee,
    maxFee,
    minRating,
    near,
    radiusKm,
    page = 1,
    limit = 10,
  } = query;

  const filters = {};

  //filter by owner adminId (for admin dashboard listing)
  if (adminId) {
    filters.adminId = Number(adminId);
  }

  // 🔍 Search by school name
  if (search) {
    filters.schoolName = {
      contains: search,
    };
  }

  // 🎓 Filter by curriculum
  if (curriculum) {
    filters.curriculum = curriculum;
  }

  // 📚 Phase 11 — filter by education level (PRE_PRIMARY / PRIMARY / SECONDARY).
  // Schools that never had a level set are intentionally excluded when the
  // filter is on; the matching enum equality also rejects nulls.
  if (schoolLevel) {
    filters.schoolLevel = schoolLevel;
  }

  // 💰 Filter by fee range
  if (minFee || maxFee) {
    filters.tuitionFee = {};
    if (minFee) filters.tuitionFee.gte = Number(minFee);
    if (maxFee) filters.tuitionFee.lte = Number(maxFee);
  }

  // ⭐ Phase 11 — "stars and up" filter. `rating` is an aggregate maintained
  // on review CRUD; schools with no reviews have rating=0 so they correctly
  // drop out when minRating > 0.
  if (minRating !== undefined && minRating !== null && Number(minRating) > 0) {
    filters.rating = { gte: Number(minRating) };
  }

  // 📍 Proximity pre-filter (bounding box). When `near` is set we ignore the
  // DB-level skip/take below and paginate the post-filtered list in JS,
  // because the actual radius check has to run after fetching candidates.
  let geo = null;
  if (near) {
    const [latStr, lngStr] = String(near).split(",");
    const lat = Number(latStr);
    const lng = Number(lngStr);
    if (
      Number.isNaN(lat) ||
      Number.isNaN(lng) ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180
    ) {
      throw new ValidationError(
        "near must be 'lat,lng' with valid coordinates",
      );
    }
    const r = radiusKm ? Number(radiusKm) : 25;
    if (!Number.isFinite(r) || r <= 0) {
      throw new ValidationError("radiusKm must be a positive number");
    }
    // 1 degree latitude ≈ 111 km. Longitude shrinks as we approach the poles.
    const latRange = r / 111;
    const cosLat = Math.cos(toRad(lat));
    const lngRange = cosLat === 0 ? 360 : r / (111 * Math.abs(cosLat));
    // lat/lng are non-nullable on School, so we don't need a `not: null`
    // guard here — the bounding-box range alone is enough.
    filters.latitude = {
      gte: lat - latRange,
      lte: lat + latRange,
    };
    filters.longitude = {
      gte: lng - lngRange,
      lte: lng + lngRange,
    };
    geo = { lat, lng, radiusKm: r };
  }

  if (geo) {
    // Fetch the bounding-box candidates (without paging), refine with the
    // exact Haversine distance, then page in memory.
    const candidates = await db.school.findMany({ where: filters });
    const enriched = candidates
      .map((s) => ({
        ...s,
        distanceKm: haversineKm(
          geo.lat,
          geo.lng,
          Number(s.latitude),
          Number(s.longitude),
        ),
      }))
      .filter((s) => s.distanceKm <= geo.radiusKm)
      .sort((a, b) => a.distanceKm - b.distanceKm);

    const total = enriched.length;
    const start = (Number(page) - 1) * Number(limit);
    const data = enriched.slice(start, start + Number(limit));
    return {
      data,
      meta: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / Number(limit)),
      },
    };
  }

  // 📄 Pagination (non-proximity path)
  const skip = (Number(page) - 1) * Number(limit);

  const [schools, total] = await Promise.all([
    db.school.findMany({
      where: filters,
      skip,
      take: Number(limit),
      orderBy: {
        createdAt: "desc",
      },
    }),
    db.school.count({ where: filters }),
  ]);

  return {
    data: schools,
    meta: {
      total,
      page: Number(page),
      limit: Number(limit),
      totalPages: Math.ceil(total / limit),
    },
  };
}

// ✅ Get Single School
export async function getSchoolById(id) {
  const school = await db.school.findUnique({
    where: { id: Number(id) },
    include: {
      admin: {
        select: {
          id: true,
          fullName: true,
          email: true,
        },
      },
      // Phase 11 — facility images surface on the detail payload so the
      // frontend can render a carousel without a second roundtrip.
      facilityImages: {
        select: { id: true, imageUrl: true },
        orderBy: { id: "asc" },
      },
      _count: {
        // Phase 4: surface the live follower count on every detail fetch so
        // the UI doesn't need a second roundtrip to /follows to render it.
        select: { subscribers: true },
      },
    },
  });

  if (!school) throw new NotFoundError("School not found");

  // Re-shape `_count.subscribers` into a top-level `followerCount` so the
  // public API stays grep-able and doesn't leak Prisma's relation-count
  // naming convention.
  const { _count, ...rest } = school;
  return { ...rest, followerCount: _count?.subscribers ?? 0 };
}

// ✅ Update School
export async function updateSchool(id, data, userId) {
  const school = await db.school.findUnique({
    where: { id: Number(id) },
  });

  if (!school) throw new NotFoundError("School not found");

  // 🔐 Ownership check
  if (school.adminId !== userId) {
    throw new ForbiddenError("Not authorized to update this school");
  }

  // `schoolLevel: null` from the client means "clear the field"; Prisma
  // accepts it directly because the column is nullable. We just forward the
  // partial body as-is.
  const updated = await db.school.update({
    where: { id: Number(id) },
    data,
  });

  return updated;
}

// ✅ Delete School
export async function deleteSchool(id, userId) {
  const school = await db.school.findUnique({
    where: { id: Number(id) },
  });

  if (!school) throw new NotFoundError("School not found");

  // 🔐 Ownership check
  if (school.adminId !== userId) {
    throw new ForbiddenError("Not authorized to delete this school");
  }

  await db.school.delete({
    where: { id: Number(id) },
  });

  return { message: "School deleted successfully" };
}
