import { db } from "../config/db.js";
import {
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";
import { logger } from "../config/logger.js";
import { createNotification } from "./notification.service.js";
import { validateContent } from "./moderation.service.js";


export async function createAnnouncement(data, user) {
  const publisherType = user.role === "MOE_OFFICER" ? "MOE" : "SCHOOL_ADMIN";

  let { schoolId, ...rest } = data;
  schoolId = schoolId === undefined || schoolId === null ? null : Number(schoolId);

  if (publisherType === "SCHOOL_ADMIN") {
    if (!schoolId) {
      throw new ValidationError(
        "schoolId is required for SCHOOL_ADMIN announcements"
      );
    }
    const school = await db.school.findUnique({
      where: { id: schoolId },
      select: { id: true, adminId: true, verificationStatus: true },
    });
    if (!school) throw new NotFoundError("School not found");
    if (school.adminId !== user.id) {
      throw new ForbiddenError("You can only post announcements for your own school");
    }
    if (school.verificationStatus === "REVOKED") {  
    throw new ForbiddenError("Schools with revoked verification cannot post announcements");  
  } 
  } else {
    // MoE-level posts are platform-wide; ignore any client-supplied schoolId.
    schoolId = null;
  }

  // Phase 5 — content moderation. Title + body both pass through the
  // validator. Throws CONTENT_REJECTED before we hit the DB.
  validateContent(rest.title, { field: "title" });
  validateContent(rest.content, { field: "content" });

  const announcement = await db.announcement.create({
    data: {
      ...rest,
      schoolId,
      publisherId: user.id,
      publisherType,
    },
  });

  // 🚀 Targeted fan-out
  try {
    let recipientIds;
    if (publisherType === "MOE") {
      const parents = await db.user.findMany({
        where: { role: "PARENT" },
        select: { id: true },
      });
      recipientIds = parents.map((p) => p.id);
    } else {
      const subs = await db.subscription.findMany({
        where: { schoolId },
        select: { parentId: true },
      });
      recipientIds = subs.map((s) => s.parentId);
    }

    await Promise.all(
      recipientIds.map((id) =>
        createNotification({
          recipientId: id,
          recipientType: "PARENT",
          message: `New announcement: ${announcement.title}`,
          sourceId: announcement.id,
          sourceType: "ANNOUNCEMENT",
        })
      )
    );
  } catch (error) {
    logger.warn({ err: error }, "Announcement notification fan-out failed");
    // Announcement creation succeeded — don't fail the request if notifications did.
  }

  return announcement;
}

export async function getAllAnnouncements(query, user) {  
  const {  
    category,  
    urgencyLevel,  
    schoolId,  
    followedOnly,  
    page = 1,  
    limit = 10,  
  } = query;  
  
  // 1. Identify schools the parent follows  
  let followedIds = [];  
  if (user && user.role === "PARENT") {  
    const subs = await db.subscription.findMany({  
      where: { parentId: user.id },  
      select: { schoolId: true },  
    });  
    followedIds = subs.map((s) => s.schoolId);  
  }  
  
  // 2. Build the base filter  
  const where = {  
    ...(category && { category }),  
    ...(urgencyLevel && { urgencyLevel }),  
    ...(schoolId && { schoolId: Number(schoolId) }),  
  };  
  
  // If the user explicitly requested "followed only", apply the filter here  
  if (followedOnly && user && user.role === "PARENT") {  
    if (followedIds.length === 0) {  
      return { data: [], meta: { total: 0, page: Number(page), totalPages: 0 } };  
    }  
    where.schoolId = { in: followedIds };  
  }  
  
  // 3. Fetch announcements  
  // Note: To prioritize followed schools across the whole set, we fetch the   
  // matches and sort in-memory before slicing for pagination.  
  const announcements = await db.announcement.findMany({  
    where,  
    orderBy: { createdAt: "desc" },  
    include: {  
      school: {  
        select: { id: true, schoolName: true, verificationStatus: true },  
      },  
    },  
  });  
  
  // 4. Prioritize followed schools while keeping newest on top  
  const sorted = announcements.sort((a, b) => {  
    const aFollowed = followedIds.includes(a.schoolId);  
    const bFollowed = followedIds.includes(b.schoolId);  
  
    if (aFollowed && !bFollowed) return -1;  
    if (!aFollowed && bFollowed) return 1;  
    return 0; // Both same status; maintain the 'createdAt desc' order from DB  
  });  
  
  // 5. Apply pagination to the sorted result  
  const skip = (Number(page) - 1) * Number(limit);  
  const paginatedData = sorted.slice(skip, skip + Number(limit));  
  
  return {  
    data: paginatedData,  
    meta: {  
      total: sorted.length,  
      page: Number(page),  
      totalPages: Math.ceil(sorted.length / limit),  
    },  
  };  
}

// ✅ Get One
export async function getAnnouncementById(id) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
    include: {
      school: {
        select: { id: true, schoolName: true, verificationStatus: true },
      },
    },
  });

  if (!announcement) throw new NotFoundError("Announcement not found");

  return announcement;
}

// Phase 11 — image upload pipeline for school announcements. The multer
// middleware writes the file to disk; this function only flips the row's
// `imgUrl` column. SCHOOL_ADMIN owns the announcement they created (and
// implicitly the school the announcement belongs to). MoE-level posts can
// also have an image attached by the MoE officer who created them.
export async function setAnnouncementImage({ id, imageUrl, userId }) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
    select: { id: true, publisherId: true },
  });
  if (!announcement) throw new NotFoundError("Announcement not found");
  if (announcement.publisherId !== userId) {
    throw new ForbiddenError(
      "You can only attach images to your own announcements"
    );
  }
  return db.announcement.update({
    where: { id: announcement.id },
    data: { imgUrl: imageUrl },
  });
}

export async function clearAnnouncementImage({ id, userId }) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
    select: { id: true, publisherId: true },
  });
  if (!announcement) throw new NotFoundError("Announcement not found");
  if (announcement.publisherId !== userId) {
    throw new ForbiddenError(
      "You can only clear images on your own announcements"
    );
  }
  return db.announcement.update({
    where: { id: announcement.id },
    data: { imgUrl: null },
  });
}

// ✅ Update
export async function updateAnnouncement(id, data, userId) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
  });

  if (!announcement) throw new NotFoundError("Announcement not found");

  if (announcement.publisherId !== userId) {
    throw new ForbiddenError("Not authorized to update this announcement");
  }

  if (data.title) validateContent(data.title, { field: "title" });
  if (data.content) validateContent(data.content, { field: "content" });

  return db.announcement.update({
    where: { id: Number(id) },
    data,
  });
}

// ✅ Delete
export async function deleteAnnouncement(id, userId) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
  });

  if (!announcement) throw new NotFoundError("Announcement not found");

  if (announcement.publisherId !== userId) {
    throw new ForbiddenError("Not authorized to delete this announcement");
  }

  await db.announcement.delete({
    where: { id: Number(id) },
  });

  return { message: "Announcement deleted successfully" };
}
