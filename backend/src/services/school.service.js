import { db } from "../config/db.js";
import {
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";

import { createNotification } from "./notification.service.js";

// ✅ Create School
export async function createSchool(data, userId) {
  const {
    schoolName,
    subCity,
    woreda,
    streetName,
    contactEmail,
    contactPhone,
    curriculum,
    schoolLevel,
    schoolType,
    tuitionFee,
    facilities,
    latitude,
    longitude,
  } = data;

  // Basic validation (also enforced at route level via Zod)
  if (!schoolName || !contactEmail || !curriculum || tuitionFee === undefined) {
    throw new ValidationError("Missing required fields");
  }

  const school = await db.school.create({
    data: {
      schoolName,
      ...(subCity ? { subCity } : {}),
      ...(woreda ? { woreda } : {}),
      ...(streetName ? { streetName } : {}),
      contactEmail,
      ...(contactPhone ? { contactPhone } : {}),
      curriculum,
      // Phase 11 — optional education level; omitted keeps the column null.
      ...(schoolLevel ? { schoolLevel } : {}),
      ...(schoolType ? { schoolType } : {}),
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

// ✅ Get All Schools with Recommendation Data (for ML service)
export async function getAllSchoolsWithRecommendationData(query) {
  const {
    adminId,
    search,
    curriculum,
    schoolLevel,
    schoolType,
    subCity,
    minFee,
    maxFee,
    minRating,
    near,
    radiusKm,
    page = 1,
    limit = 50, // Default to 50 for recommendation candidate pool
  } = query;

  const filters = {};

  // Filter by owner adminId (for admin dashboard listing)
  if (adminId) {
    filters.adminId = Number(adminId);
  }

  // Search by school name
  if (search) {
    filters.schoolName = {
      contains: search,
    };
  }

  // Filter by curriculum
  if (curriculum) {
    filters.curriculum = curriculum;
  }

  // Filter by education level
  if (schoolLevel) {
    filters.schoolLevel = schoolLevel;
  }

  // Filter by school type
  if (schoolType) {
    filters.schoolType = schoolType;
  }

  // Filter by subcity
  if (subCity) {
    filters.subCity = subCity;
  }

  // Filter by fee range
  if (minFee || maxFee) {
    filters.tuitionFee = {};
    if (minFee) filters.tuitionFee.gte = Number(minFee);
    if (maxFee) filters.tuitionFee.lte = Number(maxFee);
  }

  // Filter by rating
  if (minRating !== undefined && minRating !== null && Number(minRating) > 0) {
    filters.rating = { gte: Number(minRating) };
  }

  // Proximity pre-filter (bounding box)
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
    const latRange = r / 111;
    const cosLat = Math.cos(toRad(lat));
    const lngRange = cosLat === 0 ? 360 : r / (111 * Math.abs(cosLat));
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
    // Fetch bounding-box candidates with recommendation data
    const candidates = await db.school.findMany({
      where: filters,
      include: {
        demographics: {
          orderBy: { academicYear: "desc" },
          take: 1,
        },
        achievements: {
          where: { status: "APPROVED" },
          orderBy: { year: "desc" },
        },
        staffBreakdown: true,
        _count: {
          select: {
            subscribers: true,
            reviews: true,
          },
        },
      },
    });

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

  // Pagination (non-proximity path) with recommendation data
  const skip = (Number(page) - 1) * Number(limit);

  const [schools, total] = await Promise.all([
    db.school.findMany({
      where: filters,
      skip,
      take: Number(limit),
      orderBy: {
        createdAt: "desc",
      },
      include: {
        demographics: {
          orderBy: { academicYear: "desc" },
          take: 1,
        },
        achievements: {
          where: { status: "APPROVED" },
          orderBy: { year: "desc" },
        },
        staffBreakdown: true,
        _count: {
          select: {
            subscribers: true,
            reviews: true,
          },
        },
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

  try {
    const subs = await db.subscription.findMany({
      where: { schoolId: Number(id) },
      select: { parentId: true },
    });
    const recipientIds = subs.map((s) => s.parentId);

    await Promise.all(
      recipientIds.map((id) =>
        createNotification({
          recipientId: id,
          recipientType: "PARENT",
          message: `${updated.schoolName} updated their school information`,
          sourceId: updated.id,
          sourceType: "SCHOOL",
        }),
      ),
    );
  } catch (error) {
    logger.warn({ err: error }, "School update notification fan-out failed");
    // Update succeeded — don't fail the request if notifications did.
  }

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

export async function revokeVerification(schoolId, userId, reason) {
  const school = await db.school.findUnique({
    where: { id: schoolId },
  });

  if (!school) throw new NotFoundError("School not found");
  if (school.verificationStatus !== "VERIFIED") {
    throw new ValidationError("Only verified schools can be revoked");
  }

  const updated = await db.school.update({
    where: { id: schoolId },
    data: {
      verificationStatus: "REVOKED",
      revokedAt: new Date(),
      revokedById: userId,
      revocationReason: reason || null,
    },
  });

  // Notify the school admin about the revocation with the reason
  try {
    await createNotification({
      recipientId: school.adminId,
      recipientType: "SCHOOL_ADMIN",
      message: `Your school "${school.schoolName}" verification has been revoked by the Ministry of Education.${reason ? ` Reason: ${reason}` : ""}`,
      sourceType: "SCHOOL",
      sourceId: school.id,
    });
  } catch (error) {
    console.error(
      "Failed to notify school admin of verification revocation:",
      error,
    );
    // Don't fail the revocation if notification fails
  }

  return updated;
}
