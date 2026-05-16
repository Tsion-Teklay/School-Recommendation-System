import { db } from "../src/config/db.js";
const prisma = db;

// Hashed version of "password123"
const DEFAULT_PASSWORD_HASH = "$2b$10$76kYI9.eM.09qEozmZ.SDe6V2E.O5H.Zp9TjXp.Y0F3A4.V1O.S2W";

const rawSchoolData = [
  { name: "Eweket Amba", ownership: "Government", sector: "Primary", code: "S1001060062", x: 471000, y: 999000, tel: "112782863", lab: "1", lib: "1", ict: "1" },
  { name: "Felege Berhane", ownership: "Government", sector: "Primary", code: "S1001060052", x: 470090, y: 999027, tel: "112786491", lab: "1", lib: "1", ict: "1" },
  { name: "Glori", ownership: "Private", sector: "Primary", code: "new", x: 477199, y: 996355, tel: "911251172", lab: "1", lib: "1", ict: "1" },
  { name: "Ethio dream", ownership: "Private", sector: "KG", code: "new", x: 474903, y: 980708, tel: "911699525", lab: "0", lib: "0", ict: "0" },
  { name: "Oda Secondery School", ownership: "Government", sector: "Secondary", code: "S10", x: 478000, y: 995000, tel: "116678943", lab: "0", lib: "0", ict: "0" },
  { name: "Hachalu Hundessa", ownership: "Government", sector: "Primary", code: "S10002120032", x: 472312, y: 994000, tel: "114723121", lab: "1", lib: "1", ict: "1" },
  { name: "Dil-Ber", ownership: "Government", sector: "Primary", code: "S1001040032", x: 470500, y: 998200, tel: "112750012", lab: "1", lib: "1", ict: "1" },
  { name: "Abebe Bikila", ownership: "Government", sector: "Primary", code: "S1001040012", x: 470100, y: 997900, tel: "112751022", lab: "1", lib: "1", ict: "1" },
  { name: "Africa Andinet", ownership: "Private", sector: "Primary", code: "S1001010022", x: 469800, y: 998500, tel: "112764510", lab: "1", lib: "1", ict: "1" },
  { name: "Fitawrari Habtegeorgis", ownership: "Government", sector: "Secondary", code: "S1001060102", x: 471200, y: 999200, tel: "112134567", lab: "1", lib: "1", ict: "1" },
  { name: "Tana Haik", ownership: "Government", sector: "Secondary", code: "S1001010152", x: 470000, y: 998000, tel: "112756677", lab: "1", lib: "1", ict: "1" },
  { name: "Addis Ketema", ownership: "Government", sector: "Secondary", code: "S1001040112", x: 470400, y: 997500, tel: "112768899", lab: "1", lib: "1", ict: "1" },
  { name: "Yekatit 23", ownership: "Government", sector: "Primary", code: "S1001020052", x: 468900, y: 998100, tel: "112704433", lab: "1", lib: "1", ict: "0" },
  { name: "Hibret Secondary", ownership: "Government", sector: "Secondary", code: "S1001010082", x: 469500, y: 998800, tel: "112759900", lab: "1", lib: "1", ict: "1" },
  { name: "Medhanialem", ownership: "Government", sector: "Secondary", code: "S1002010112", x: 472500, y: 999500, tel: "116294021", lab: "1", lib: "1", ict: "1" },
  { name: "Bole Community", ownership: "Private", sector: "Secondary", code: "S1004010122", x: 478500, y: 996000, tel: "116630707", lab: "1", lib: "1", ict: "1" },
  { name: "Andinet International", ownership: "Private", sector: "Primary", code: "S1004020151", x: 480100, y: 997200, tel: "116464301", lab: "1", lib: "1", ict: "1" },
  { name: "Dandii Boru", ownership: "Private", sector: "Secondary", code: "S1003010101", x: 474500, y: 995800, tel: "115529988", lab: "1", lib: "1", ict: "1" },
  { name: "Nazareth School", ownership: "Private", sector: "Secondary", code: "S1003010121", x: 474800, y: 995500, tel: "115512755", lab: "1", lib: "1", ict: "1" },
  { name: "St. Joseph", ownership: "Private", sector: "Secondary", code: "S1003010131", x: 474200, y: 995900, tel: "115512344", lab: "1", lib: "1", ict: "1" },
  { name: "Assai Public School", ownership: "Private", sector: "Secondary", code: "S1004010142", x: 479200, y: 996500, tel: "116613651", lab: "1", lib: "1", ict: "1" },
  { name: "Abadir", ownership: "Government", sector: "Primary", code: "S1001030042", x: 470200, y: 997200, tel: "112754422", lab: "0", lib: "1", ict: "0" },
  { name: "Ras Abebe Aregay", ownership: "Government", sector: "Primary", code: "S1001050022", x: 470800, y: 998000, tel: "112756611", lab: "1", lib: "1", ict: "0" },
  { name: "Kokebe Tsiba", ownership: "Government", sector: "Secondary", code: "S1005010112", x: 482500, y: 999200, tel: "116460011", lab: "1", lib: "1", ict: "1" },
  { name: "Menelik II", ownership: "Government", sector: "Secondary", code: "S1002010152", x: 473200, y: 999000, tel: "111566788", lab: "1", lib: "1", ict: "1" },
  { name: "St. Mary", ownership: "Private", sector: "Secondary", code: "S1003010161", x: 473900, y: 995200, tel: "115511211", lab: "1", lib: "1", ict: "1" },
  { name: "School of Nations", ownership: "Private", sector: "Primary", code: "S1004020181", x: 481200, y: 997800, tel: "116630000", lab: "1", lib: "1", ict: "1" },
  { name: "Lycée Guebre-Mariam", ownership: "Private", sector: "Secondary", code: "S1002010191", x: 472800, y: 998800, tel: "111551211", lab: "1", lib: "1", ict: "1" },
  { name: "Black Lion", ownership: "Government", sector: "Secondary", code: "S1003010202", x: 474000, y: 995000, tel: "115515677", lab: "1", lib: "1", ict: "1" },
  { name: "Ethio-Parents", ownership: "Private", sector: "Secondary", code: "S1004020211", x: 481500, y: 998200, tel: "116463321", lab: "1", lib: "1", ict: "1" }
];

function mapLevel(sector) {
  const s = sector?.toUpperCase();
  if (s === "KG") return "PRE_PRIMARY";
  if (s === "PRIMARY") return "PRIMARY";
  if (s === "SECONDARY") return "SECONDARY";
  return "PRIMARY";
}

// Convert UTM/X-Y to estimated Decimal Degrees for Addis Ababa
function convertCoords(val, isLat) {
  if (val < 100) return val; // Already decimal
  return isLat ? 9.0 + (val % 10000) / 100000 : 38.7 + (val % 10000) / 100000;
}

async function main() {
  console.log("Seeding 30 schools from MoE data...");

  for (const s of rawSchoolData) {
    const adminEmail = `admin.${s.name.toLowerCase().replace(/\s+/g, '')}@moe-edu.et`;

    await prisma.user.upsert({
      where: { email: adminEmail },
      update: {},
      create: {
        fullName: `${s.name} Administrator`,
        email: adminEmail,
        password: DEFAULT_PASSWORD_HASH,
        role: "SCHOOL_ADMIN",
        accountStatus: "ACTIVE",
        emailVerified: true,
        administeredSchools: {
          create: {
            schoolName: s.name,
            address: "Addis Ababa, Ethiopia",
            contactEmail: adminEmail,
            contactPhone: s.tel || "0110000000",
            curriculum: s.ownership === "Private" ? "INTERNATIONAL" : "LOCAL",
            schoolLevel: mapLevel(s.sector),
            tuitionFee: s.ownership === "Private" ? 2500.00 : 0.00,
            facilities: `Lab: ${s.lab}, Library: ${s.lib}, ICT: ${s.ict}`,
            verificationStatus: "VERIFIED",
            latitude: convertCoords(s.x, true),
            longitude: convertCoords(s.y, false),
          }
        }
      }
    });
  }
  console.log("Seed complete.");
}

main().catch(e => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());