import { db } from "../../config/db.js";

export const cleanDatabase = async () => {
  // Order matters: delete dependent rows before their parents to respect FKs.
  await db.analytics.deleteMany();
  await db.notification.deleteMany();
  await db.moderatorAction.deleteMany();
  await db.report.deleteMany();
  await db.review.deleteMany();
  await db.announcement.deleteMany();
  await db.favorite.deleteMany();
  await db.preference.deleteMany();
  // Phase 2: subscription + verification_request hold FKs to school + user.
  await db.subscription.deleteMany();
  await db.verificationRequest.deleteMany();
  await db.school.deleteMany();
  await db.parent.deleteMany();
  await db.user.deleteMany();
};
