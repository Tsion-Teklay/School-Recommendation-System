import { db } from "../config/db.js";

// ✅ Create School
export async function createSchool(data, userId) {
  const {
    schoolName,
    address,
    contactEmail,
    contactPhone,
    curriculum,
    tuitionFee,
    facilities,
    latitude,
    longitude,
  } = data;

  // Basic validation
  if (!schoolName || !address || !contactEmail || !curriculum || !tuitionFee) {
    throw new Error("Missing required fields");
  }

  const school = await db.school.create({
    data: {
      schoolName,
      address,
      contactEmail,
      contactPhone,
      curriculum,
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

// ✅ Get All Schools (PUBLIC)
export async function getAllSchools(query) {
  const {
    search,
    curriculum,
    minFee,
    maxFee,
    page = 1,
    limit = 10,
  } = query;

  const filters = {};

  // 🔍 Search by school name
  if (search) {
    filters.schoolName = {
      contains: search,
      //mode: "insensitive",
    };
  }

  // 🎓 Filter by curriculum
  if (curriculum) {
    filters.curriculum = curriculum;
  }

  // 💰 Filter by fee range
  if (minFee || maxFee) {
    filters.tuitionFee = {};
    if (minFee) filters.tuitionFee.gte = Number(minFee);
    if (maxFee) filters.tuitionFee.lte = Number(maxFee);
  }

  // 📄 Pagination
  const skip = (Number(page) - 1) * Number(limit);

  const [schools, total] = await Promise.all([
    db.school.findMany({
      where: filters,
      skip,
      take: Number(limit),
      orderBy: {
        createdAt: "desc", // optional (if you add createdAt later)
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
    },
  });

  if (!school) throw new Error("School not found");

  return school;
}

// ✅ Update School
export async function updateSchool(id, data, userId) {
  const school = await db.school.findUnique({
    where: { id: Number(id) },
  });

  if (!school) throw new Error("School not found");

  // 🔐 Ownership check
  if (school.adminId !== userId) {
    throw new Error("Not authorized to update this school");
  }

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

  if (!school) throw new Error("School not found");

  // 🔐 Ownership check
  if (school.adminId !== userId) {
    throw new Error("Not authorized to delete this school");
  }

  await db.school.delete({
    where: { id: Number(id) },
  });

  return { message: "School deleted successfully" };
}