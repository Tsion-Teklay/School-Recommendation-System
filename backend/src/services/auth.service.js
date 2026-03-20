import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { db } from "../config/db.js"; 

const SALT_ROUNDS = 10;

export async function registerUser({ fullName, email, phone, password, role }) {
  // 1. Check if user already exists
  const existing = await db.user.findUnique({ where: { email } });
  if (existing) throw new Error("Email already registered");

  // 2. Hash password
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

  // 3. Create user
  const user = await db.user.create({
    data: {
      fullName,
      email,
      phone,
      password: hashedPassword,
      accountStatus: "ACTIVE", // default for new user
      role
    },
  });

  return user;
}

export async function loginUser({ email, password }) {
  const user = await db.user.findUnique({ where: { email } });
  if (!user) throw new Error("Invalid credentials");

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new Error("Invalid credentials");

  // Generate JWT
  const token = jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "1d" }
  );

  return { token, user };
}