import { db } from "../config/db.js";
import { NotFoundError } from "../utils/errors.js";

const PUBLIC_USER_SELECT = {
  id: true,
  fullName: true,
  email: true,
  phone: true,
  role: true,
  accountStatus: true,
  emailVerified: true,
  createdAt: true,
  updatedAt: true,
};

export async function getMe(userId) {
  const user = await db.user.findUnique({
    where: { id: userId },
    select: PUBLIC_USER_SELECT,
  });
  if (!user) throw new NotFoundError("User not found");
  return user;
}

export async function updateMe(userId, { fullName, phone }) {
  // Only allow these two — email/role/status changes are separate flows.
  const data = {};
  if (fullName !== undefined) data.fullName = fullName;
  if (phone !== undefined) data.phone = phone;

  const user = await db.user.update({
    where: { id: userId },
    data,
    select: PUBLIC_USER_SELECT,
  });
  return user;
}

export async function deactivateMe(userId) {
  const user = await db.user.update({
    where: { id: userId },
    data: { accountStatus: "DEACTIVATED" },
    select: PUBLIC_USER_SELECT,
  });
  return user;
}
