import "dotenv/config";
import { PrismaMariaDb } from "@prisma/adapter-mariadb";
import prismaPkg from "@prisma/client";

const { PrismaClient } = prismaPkg;

const adapter = new PrismaMariaDb({
  host: process.env.DATABASE_HOST,
  user: process.env.DATABASE_USER,
  password: process.env.DATABASE_PASSWORD,
  database: process.env.DATABASE_NAME,
  connectionLimit: 10,
  ssl: {
    ca: fs.readFileSync("./prisma/ca.pem").toString(), // ✅ explicitly load the cert
  },
});
const db = new PrismaClient({ adapter });

export { db };
