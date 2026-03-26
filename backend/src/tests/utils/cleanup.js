import { db } from "../../config/db.js";

export const cleanDatabase = async () => {
  await db.notification.deleteMany();
  await db.moderatorAction.deleteMany();
  await db.report.deleteMany();
  await db.review.deleteMany();
  await db.announcement.deleteMany();
  await db.favorite.deleteMany();
  await db.preference.deleteMany();
  await db.school.deleteMany();
  await db.parent.deleteMany();
  await db.user.deleteMany();
};