const { PrismaClient, Curriculum, SchoolLevel, UserRole, AccountStatus } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  // 1. Create a dummy School Admin first
  const admin = await prisma.user.upsert({
    where: { email: 'admin@test.com' },
    update: {},
    create: {
      fullName: 'Default Admin',
      email: 'admin@test.com',
      password: 'hashedpassword123', // In real life, hash this!
      role: UserRole.SCHOOL_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      emailVerified: true
    }
  });

  // 2. Define 20 schools
  const schoolsData = [
    {
      adminId: admin.id,
      schoolName: "Addis International Academy",
      address: "Bole, Addis Ababa",
      contactEmail: "info@addisacademy.com",
      contactPhone: "0911223344",
      curriculum: Curriculum.INTERNATIONAL,
      schoolLevel: SchoolLevel.SECONDARY,
      tuitionFee: 15500.50,
      rating: 4.8,
      latitude: 9.0128,
      longitude: 38.7525,
      facilities: "Swimming Pool, IT Lab, Science Lab, Football Pitch",
      verificationStatus: "VERIFIED"
    },
    {
      adminId: admin.id,
      schoolName: "Ethio-Knowledge School",
      address: "Megenagna, Addis Ababa",
      contactEmail: "contact@ethioschool.com",
      contactPhone: "0911556677",
      curriculum: Curriculum.LOCAL,
      schoolLevel: SchoolLevel.PRIMARY,
      tuitionFee: 4200.00,
      rating: 3.9,
      latitude: 9.0333,
      longitude: 38.7667,
      facilities: "Library, Playground",
      verificationStatus: "VERIFIED"
    }
    // ... we will generate the rest in the loop below
  ];

  // Fill up to 20 schools with random variations
  for (let i = 3; i <= 20; i++) {
    schoolsData.push({
      adminId: admin.id,
      schoolName: `Standard School ${i}`,
      address: `Area ${i}, Addis Ababa`,
      contactEmail: `school${i}@test.com`,
      contactPhone: `09220000${i}`,
      curriculum: i % 3 === 0 ? Curriculum.INTERNATIONAL : Curriculum.LOCAL,
      schoolLevel: i % 2 === 0 ? SchoolLevel.PRIMARY : SchoolLevel.SECONDARY,
      tuitionFee: Math.floor(Math.random() * (18000 - 3000) + 3000),
      rating: parseFloat((Math.random() * (5 - 2) + 2).toFixed(2)),
      latitude: 9.03 + (Math.random() - 0.5) * 0.05,
      longitude: 38.74 + (Math.random() - 0.5) * 0.05,
      facilities: "Library, Science Lab",
      verificationStatus: "VERIFIED"
    });
  }

  console.log("Seeding Database...");
  await prisma.school.createMany({ data: schoolsData });
  console.log("✅ Seeded 20 schools successfully.");
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });