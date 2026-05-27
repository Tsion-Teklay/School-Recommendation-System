import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  // 1. Force the library engine here so it never errors out again
  client: {
    engineType: "library",
  },
  migrations: {
    path: "prisma/migrations",
    // 2. This tells 'prisma db seed' exactly what command to run
    seed: "node ./prisma/seed.js",
  },
  datasource: {
    url: process.env["DATABASE_URL"],
  },
});
