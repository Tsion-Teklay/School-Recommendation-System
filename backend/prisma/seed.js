const { PrismaClient } = require("@prisma/client");
const fs = require("fs");
const path = require("path");
const { parse } = require("csv-parse/sync");

const prisma = new PrismaClient();

// Helper function to safely match schema enum values (uppercase string formatting)
const toEnumFormat = (val) => (val ? val.trim().toUpperCase() : undefined);

async function main() {
  console.log("🌱 Starting database seeding...");

  const csvFilePath = path.join(__dirname, "school_data.csv");
  const fileContent = fs.readFileSync(csvFilePath, "utf-8");

  const records = parse(fileContent, {
    columns: true,
    skip_empty_lines: true,
  });

  for (const row of records) {
    try {
      await prisma.$transaction(async (tx) => {
        // Step A: Create the Admin under the generic 'user' model
        const newAdmin = await tx.user.create({
          data: {
            fullName: row.admin_name || "School Admin",
            email: row.contact_email,
            password: "temporary_secure_password", // Replace with a real hash in production
            role: "SCHOOL_ADMIN", // Matches your UserRole enum definition
            accountStatus: "ACTIVE",
          },
        });

        // Step B: Create the School and inject the dynamic admin user ID
        await tx.school.create({
          data: {
            adminId: newAdmin.id, // Primary key reference from your User model
            schoolName: row.school_name,
            address: row.address,
            contactEmail: row.contact_email,
            contactPhone: row.contact_phone,
            curriculum: toEnumFormat(row.curriculum) || "LOCAL", // Fallback defaults if blank
            tuitionFee: parseFloat(row.tuition_fee) || 0.0,
            facilities: row.facilities || null,
            verificationStatus:
              toEnumFormat(row.verification_status) || "PENDING",
            latitude: parseFloat(row.latitude),
            longitude: parseFloat(row.longitude),
            rating: parseFloat(row.rating) || 0.0,
            reviewCount: parseInt(row.review_count, 10) || 0,
            schoolLevel: toEnumFormat(row.school_level) || null,
            schoolType: toEnumFormat(row.school_type) || null,
          },
        });
      });

      console.log(`✅ Successfully seeded: ${row.school_name}`);
    } catch (error) {
      console.error(
        `❌ Error seeding row for ${row.school_name}:`,
        error.message,
      );
    }
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
