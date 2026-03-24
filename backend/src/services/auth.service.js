import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { db } from "../config/db.js";

const SALT_ROUNDS = 10;

// 🔒 remove password before returning user
function sanitizeUser(user) {
  const { password, ...safeUser } = user;
  return safeUser;
}

export async function registerUser({
  fullName,
  email,
  phone,
  password,
  role,
}) {
  // ✅ Basic validation
  if (!fullName || !email || !password || !role) {
    throw new Error("Missing required fields");
  }

  const normalizedEmail = email.toLowerCase();

  // 1. Check if user already exists
  const existing = await db.user.findUnique({
    where: { email: normalizedEmail },
  });

  if (existing) throw new Error("Email already registered");

  // 2. Hash password
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

  // 3. Create user
  const user = await db.user.create({
    data: {
      fullName,
      email: normalizedEmail,
      phone,
      password: hashedPassword,
      accountStatus: "ACTIVE",
      role,
    },
  });

  return sanitizeUser(user);
}

export async function loginUser({ email, password }) {
  if (!email || !password) {
    throw new Error("Email and password are required");
  }

  const normalizedEmail = email.toLowerCase();

  const user = await db.user.findUnique({
    where: { email: normalizedEmail },
  });

  if (!user) throw new Error("Invalid credentials");

  // 🚫 Block deactivated users
  if (user.accountStatus !== "ACTIVE") {
    throw new Error("Account is deactivated");
  }

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new Error("Invalid credentials");

  // Generate JWT
  const token = jwt.sign(
    {
      userId: user.id,
      role: user.role,
    },
    process.env.JWT_SECRET,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || "1d",
    }
  );

  return {
    token,
    user: sanitizeUser(user),
  };
}