import { db } from "../config/db.js";  
import { NotFoundError, ForbiddenError, ValidationError } from "../utils/errors.js";  
import { createNotification } from "./notification.service.js";  
  
const TIER_SCORES = {  
  GOLD: 100,  
  SILVER: 50,  
  BRONZE: 25,  
};  
  
// Achievement CRUD
export async function createAchievement(data, userId) {
  const { schoolId, title, description, year, documents } = data;

  // Validate required fields
  if (!schoolId) throw new ValidationError("School ID is required");
  if (!title) throw new ValidationError("Title is required");
  if (!year) throw new ValidationError("Year is required");
  if (!documents || documents.length === 0) {
    throw new ValidationError("At least one document is required");
  }

  // Verify user owns the school
  const school = await db.school.findUnique({
    where: { id: Number(schoolId) }
  });

  if (!school) throw new NotFoundError("School not found");
  if (school.adminId !== userId) throw new ForbiddenError("You can only add achievements to your own school");

  const result = await db.achievement.create({
    data: {
      schoolId: Number(schoolId),
      title: title.trim(),
      description: description?.trim() || null,
      year: typeof year === 'string' ? parseInt(year, 10) : Number(year),
      documents: JSON.stringify(documents),
      status: "PENDING",
      // tier and score will be assigned by MOE officer during review
    },
  });

  return result;
}  
  
export async function getSchoolAchievements(schoolId) {  
  const achievements = await db.achievement.findMany({  
    where: { schoolId },  
    orderBy: { year: 'desc' },  
  });  
    
  return achievements;  
}  
  
export async function getPendingAchievements() {  
  const achievements = await db.achievement.findMany({  
    where: { status: "PENDING" },  
    include: { school: true },  
    orderBy: { submittedAt: 'asc' },  
  });  
    
  return achievements;  
}  
  
export async function reviewAchievement(id, data, userId) {
  const { status, reviewNotes, tier } = data;

  const achievement = await db.achievement.findUnique({
    where: { id },
    include: { school: true }
  });

  if (!achievement) throw new NotFoundError("Achievement not found");
  if (achievement.status !== "PENDING") throw new ValidationError("Achievement has already been reviewed");

  // If approving, tier must be provided
  if (status === "APPROVED" && !tier) {
    throw new ValidationError("Tier must be provided when approving an achievement");
  }

  const updated = await db.$transaction(async (tx) => {
    const updateData = {
      status,
      reviewedById: userId,
      reviewNotes: reviewNotes || null,
      reviewedAt: new Date(),
    };

    // If approving, assign tier and calculate score
    if (status === "APPROVED") {
      updateData.tier = tier;
      updateData.score = TIER_SCORES[tier];
    }

    const updatedAchievement = await tx.achievement.update({
      where: { id },
      data: updateData,
    });

    // If approved, update the school's total achievement score
    if (status === "APPROVED") {
      const currentScore = achievement.school.totalAchievementScore || 0;
      const newScore = currentScore + TIER_SCORES[tier];

      await tx.school.update({
        where: { id: achievement.schoolId },
        data: { totalAchievementScore: newScore },
      });
    }

    return updatedAchievement;
  });

  // Notify the school admin with the achieved tier/score
  try {
    await createNotification({
      recipientId: achievement.school.adminId,
      recipientType: "SCHOOL_ADMIN",
      message: status === "APPROVED"
        ? `Your achievement "${achievement.title}" has been approved by the Ministry of Education. You achieved ${tier} tier (${TIER_SCORES[tier]} points)!`
        : `Your achievement "${achievement.title}" was rejected${reviewNotes ? `: ${reviewNotes}` : "."}`,
      sourceType: "SCHOOL",
      sourceId: achievement.schoolId,
    });
  } catch {
    // intentional swallow
  }

  return updated;
}  
  
export async function deleteAchievement(id, userId) {  
  const achievement = await db.achievement.findUnique({  
    where: { id },  
    include: { school: true }  
  });  
    
  if (!achievement) throw new NotFoundError("Achievement not found");  
  if (achievement.school.adminId !== userId) throw new ForbiddenError("You can only delete your own achievements");  
  if (achievement.status !== "PENDING") throw new ValidationError("Cannot delete reviewed achievements");  
    
  return db.achievement.delete({ where: { id } });  
}  
  
// Staff Breakdown CRUD  
export async function createStaffBreakdown(data, userId) {  
  const { schoolId, educationLevel, count } = data;  
    
  const school = await db.school.findUnique({  
    where: { id: schoolId }  
  });  
    
  if (!school) throw new NotFoundError("School not found");  
  if (school.adminId !== userId) throw new ForbiddenError("You can only add staff breakdown to your own school");  
    
  return db.staffBreakdown.create({  
    data: { schoolId, educationLevel, count },  
  });  
}  
  
export async function getSchoolStaffBreakdown(schoolId) {  
  const breakdown = await db.staffBreakdown.findMany({  
    where: { schoolId },  
  });  
    
  return breakdown;  
}  
  
export async function updateStaffBreakdown(id, data, userId) {  
  const existing = await db.staffBreakdown.findUnique({  
    where: { id },  
    include: { school: true }  
  });  
    
  if (!existing) throw new NotFoundError("Staff breakdown not found");  
  if (existing.school.adminId !== userId) throw new ForbiddenError("You can only update your own school's staff breakdown");  
    
  return db.staffBreakdown.update({  
    where: { id },  
    data,  
  });  
}  
  
export async function deleteStaffBreakdown(id, userId) {  
  const existing = await db.staffBreakdown.findUnique({  
    where: { id },  
    include: { school: true }  
  });  
    
  if (!existing) throw new NotFoundError("Staff breakdown not found");  
  if (existing.school.adminId !== userId) throw new ForbiddenError("You can only delete your own school's staff breakdown");  
    
  return db.staffBreakdown.delete({ where: { id } });  
}