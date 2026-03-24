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
export async function getAllSchools() {
  return db.school.findMany({
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