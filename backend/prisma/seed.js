import { PrismaClient } from "@prisma/client/index.js";
import { PrismaMariaDb } from "@prisma/adapter-mariadb";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { parse } from "csv-parse/sync";

// 1. Safely break down your environment connection URL
const dbUrl = new URL(process.env.DATABASE_URL);
const dbName = dbUrl.pathname.replace(/^\//, "");

// 2. Instantiate the PrismaMariaDb driver adapter natively with a configuration object
// The adapter manages its own internal pool using the properties provided below.
const adapter = new PrismaMariaDb({
  host: dbUrl.hostname,
  port: parseInt(dbUrl.port, 10) || 3306,
  user: dbUrl.username,
  password: decodeURIComponent(dbUrl.password),
  database: dbName,
  connectionLimit: 10
});

// 3. Supply the native adapter to your Prisma Client instance
const prisma = new PrismaClient({ adapter });

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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
        const newAdmin = await tx.user.create({
          data: {
            fullName: row.admin_name || "School Admin",
            email: row.contact_email,
            password: "temporary_secure_password",
            role: "SCHOOL_ADMIN",
            accountStatus: "ACTIVE",
          },
        });

        await tx.school.create({
          data: {
            adminId: newAdmin.id,
            schoolName: row.school_name,
            address: row.address,
            contactEmail: row.contact_email,
            contactPhone: row.contact_phone,
            curriculum: toEnumFormat(row.curriculum) || "LOCAL",
            tuitionFee: parseFloat(row.tuition_fee) || 0.0,
            facilities: row.facilities || null,
            verificationStatus: toEnumFormat(row.verification_status) || "PENDING",
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
        error.message
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