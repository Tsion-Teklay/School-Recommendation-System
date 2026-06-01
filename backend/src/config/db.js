import "dotenv/config";
import { PrismaMariaDb } from "@prisma/adapter-mariadb";
import prismaPkg from "@prisma/client";

const { PrismaClient } = prismaPkg;

const adapter = new PrismaMariaDb({
    host: process.env.DATABASE_HOST,
    port: Number(process.env.DATABASE_PORT),
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE_NAME,
    connectTimeout: 10000,
    ssl: { rejectUnauthorized: false },
});
const db = new PrismaClient({ adapter });

export { db };
