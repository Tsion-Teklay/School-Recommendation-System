import { db } from "../config/db.js";
import { ConflictError, NotFoundError } from "../utils/errors.js";

/**
 * Follow / Subscribe.
 *
 * Subscriptions back the targeted-announcement fan-out: when a SCHOOL_ADMIN
 * publishes an announcement, only parents subscribed to that school get a
 * notification (UC09 / UC18 / UC21). MoE announcements still broadcast to
 * every parent — that path lives in announcement.service.
 */

/**
 * Subscribe the calling parent to a school. Idempotent at the DB level via
 * the (parentId, schoolId) unique index — surfacing a 409 if the parent is
 * already a subscriber instead of silently no-oping, so the client can decide
 * whether to treat it as success or show a "you already follow this" state.
 */
export async function followSchool(userId, schoolId) {
  const school = await db.school.findUnique({
    where: { id: Number(schoolId) },
  });
  if (!school) throw new NotFoundError("School not found");

  const existing = await db.subscription.findUnique({
    where: {
      parentId_schoolId: {
        parentId: userId,
        schoolId: Number(schoolId),
      },
    },
  });
  if (existing) throw new ConflictError("Already following this school");

  return db.subscription.create({
    data: {
      parentId: userId,
      schoolId: Number(schoolId),
    },
    include: {
      school: {
        select: { id: true, schoolName: true, curriculum: true },
      },
    },
  });
  await db.recommendedSchool.updateMany({  
  where: {  
    schoolId: schoolId,  
    recommendation: {  
      userId: req.user.id  
    }  
  },  
  data: { interactionResult: "FOLLOWED" }  
});
}

/** Unsubscribe; 404 if the caller wasn't following the school. */
export async function unfollowSchool(userId, schoolId) {
  const existing = await db.subscription.findUnique({
    where: {
      parentId_schoolId: {
        parentId: userId,
        schoolId: Number(schoolId),
      },
    },
  });
  if (!existing) throw new NotFoundError("Not following this school");

  await db.subscription.delete({ where: { id: existing.id } });
  return { message: "Unfollowed" };
}

/**
 * Paginated list of the schools the calling parent follows. School payload
 * is intentionally narrow (id/name/curriculum/rating) so the client can
 * render the "My Follows" list without a second call per row.
 */
export async function listMyFollows(userId, { page = 1, limit = 10 } = {}) {
  const skip = (Number(page) - 1) * Number(limit);

  const [subs, total] = await Promise.all([
    db.subscription.findMany({
      where: { parentId: userId },
      include: {
        school: {
          select: {
            id: true,
            schoolName: true,
            curriculum: true,
            rating: true,
            reviewCount: true,
            verificationStatus: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
      skip,
      take: Number(limit),
    }),
    db.subscription.count({ where: { parentId: userId } }),
  ]);

  return {
    data: subs,
    meta: {
      total,
      page: Number(page),
      limit: Number(limit),
      totalPages: Math.ceil(total / Number(limit)),
    },
  };
}

/** Internal: count of subscribers for a school (used by school detail). */
export async function getFollowerCount(schoolId) {
  return db.subscription.count({ where: { schoolId: Number(schoolId) } });
}
