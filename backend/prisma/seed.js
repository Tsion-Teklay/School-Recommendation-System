import {
  UserRole,
  AccountStatus,
  Curriculum,
  SchoolLevel,
  VerificationStatus,
} from "@prisma/client";
import { db } from "../src/config/db.js";
const prisma = db;

async function main() {
  console.log("Cleaning up old seed data...");
  // Clear schools first because they depend on users
  await prisma.school.deleteMany({});
  await prisma.user.deleteMany({ where: { role: UserRole.SCHOOL_ADMIN } });

  const totalSchools = 20;
  console.log(`Starting seed for ${totalSchools} schools...`);

  for (let i = 1; i <= totalSchools; i++) {
    const email = `admin${i}@school.com`;

    await prisma.user.create({
      data: {
        fullName: `Admin of School ${i}`,
        email: email,
        password: "hashed_password_123", // Realistically, hash this with bcrypt
        role: UserRole.SCHOOL_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
        emailVerified: true,
        // Nested creation of the school
        administeredSchools: {
          create: {
            schoolName:
              i === 1 ? "Addis International Academy" : `Standard School ${i}`,
            address: `Addis Ababa, Zone ${i}`,
            contactEmail: `info@school${i}.com`,
            contactPhone: `09110000${i.toString().padStart(2, "0")}`,
            curriculum:
              i % 3 === 0 ? Curriculum.INTERNATIONAL : Curriculum.LOCAL,
            schoolLevel:
              i % 2 === 0 ? SchoolLevel.PRIMARY : SchoolLevel.SECONDARY,
            tuitionFee: Math.floor(Math.random() * (20000 - 5000) + 5000),
            latitude: 9.0128 + (Math.random() - 0.5) * 0.1,
            longitude: 38.7525 + (Math.random() - 0.5) * 0.1,
            facilities: "Library, Science Lab, Playground",
            verificationStatus: VerificationStatus.VERIFIED,
            rating: parseFloat((Math.random() * (5 - 3) + 3).toFixed(2)),
            reviewCount: 0,
          },
        },
      },
    });
  }

  console.log(
    `✅ Successfully seeded ${totalSchools} schools with 20 unique admins.`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
