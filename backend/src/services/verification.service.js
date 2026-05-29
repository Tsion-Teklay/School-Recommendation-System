import { db } from "../config/db.js";
import { logger } from "../config/logger.js";
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";
import { createNotification } from "./notification.service.js";

/**
 * School-verification workflow.
 *
 * Lifecycle:
 *   1. SCHOOL_ADMIN owner of a school submits a `VerificationRequest` with
 *      one or more document URLs (uploaded via the multer pipeline).
 *   2. The school is left at `verificationStatus = PENDING` (its default
 *      from creation) — we never flip the school here on submit.
 *   3. An MOE_OFFICER reviews the request and posts an APPROVED / REJECTED
 *      decision with optional `reviewNotes`.
 *   4. The school's `verificationStatus` is updated to mirror the decision
 *      (APPROVED → VERIFIED, REJECTED → REJECTED) and the submitter
 *      receives a notification (`sourceType: SCHOOL`, `sourceId: schoolId`).
 *
 * Only the latest non-resolved request per school can be PENDING — we
 * reject duplicate submissions while one is already open. Approved /
 * rejected requests are immutable history; a school admin can re-submit
 * after a rejection to start a fresh request.
 */

function toIntId(id, label = "id") {
  const parsed = Number(id);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new ValidationError(`Invalid ${label}`);
  }
  return parsed;
}

async function loadSchoolForOwner(schoolId, userId) {
  const id = toIntId(schoolId, "schoolId");
  const school = await db.school.findUnique({ where: { id } });
  if (!school) throw new NotFoundError("School not found");
  if (school.adminId !== userId) {
    throw new ForbiddenError("Not authorized to manage this school");
  }
  return school;
}

// -----------------------------------------------------------------------------
// Submit (SCHOOL_ADMIN)
// -----------------------------------------------------------------------------

export async function submitVerificationRequest({  
  schoolId,  
  userId,  
  documents,  
  notes,  
}) {  
  const school = await loadSchoolForOwner(schoolId, userId);  
  
  if (!Array.isArray(documents) || documents.length === 0) {  
    throw new ValidationError("At least one supporting document is required");  
  }  
  
  const existingPending = await db.verificationRequest.findFirst({  
    where: { schoolId: school.id, status: "PENDING" },  
  });  
  if (existingPending) {  
    throw new ConflictError(  
      "A verification request for this school is already pending review"  
    );  
  }  
  
  const request = await db.verificationRequest.create({
    data: {
      schoolId: school.id,
      submittedById: userId,
      documents: JSON.stringify(documents),
      notes: notes || null,
    },
  });  
  
  // Notify MOE officer based on subcity  
  try {  
    const assignedOfficer = await assignVerificationRequest(request.id);  
    if (assignedOfficer) {  
      await createNotification({  
        recipientId: assignedOfficer.userId,  
        recipientType: "MOE",  
        message: `New verification request for school "${school.schoolName}" in ${school.subCity || 'your assigned area'}.`,  
        sourceType: "SCHOOL",  
        sourceId: school.id,  
      });  
    }  
  } catch (err) {
    logger.warn({ err, requestId: request.id }, "Failed to notify MOE officer of verification request");
  }

  // Return the created request with parsed documents
  return {
    ...request,
    documents: request.documents ? JSON.parse(request.documents) : null,
  };  
}

// -----------------------------------------------------------------------------
// List
// -----------------------------------------------------------------------------

/**
 * MOE_OFFICER → requests filtered by subcity assignment, or all if no assignment.
 * SCHOOL_ADMIN → only requests for schools they own.
 */
export async function listVerificationRequests({ user, query }) {
  const { status, schoolId, page = 1, limit = 10 } = query;

  const where = {};
  if (status) where.status = status;
  if (schoolId) where.schoolId = toIntId(schoolId, "schoolId");

  if (user.role === "SCHOOL_ADMIN") {
    where.school = { adminId: user.id };
  } else if (user.role === "MOE_OFFICER") {
    // Get the MOE officer's subcity assignment
    try {
      const officer = await db.moeOfficer.findUnique({
        where: { userId: user.id }
      });

      // If officer has a subcity assignment, filter by it
      if (officer && officer.subCity) {
        where.school = { subCity: officer.subCity };
      }
      // If no subcity assignment, show all requests (fallback behavior)
    } catch (error) {
      // If officer lookup fails, log but don't block the request
      logger.warn({ error, userId: user.id }, "Failed to lookup MOE officer subcity assignment, showing all requests");
    }
  } else {
    // Defence-in-depth — route-layer authorize() already blocks this.
    throw new ForbiddenError("Not authorized to list verification requests");
  }

  const skip = (Number(page) - 1) * Number(limit);

  try {
    const [data, total] = await Promise.all([
      db.verificationRequest.findMany({
        where,
        skip,
        take: Number(limit),
        orderBy: { submittedAt: "desc" },
        include: {
          school: { select: { id: true, schoolName: true, adminId: true, subCity: true } },
          submittedBy: { select: { id: true, fullName: true, email: true } },
          reviewedBy: { select: { id: true, fullName: true, email: true } },
        },
      }),
      db.verificationRequest.count({ where }),
    ]);

  // Parse documents JSON strings back to arrays
  const parsedData = data.map(request => ({
    ...request,
    documents: request.documents ? JSON.parse(request.documents) : null,
  }));

    return {
      data: parsedData,
      meta: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / Number(limit)),
      },
    };
  } catch (error) {
    logger.error({ error, where }, "Failed to fetch verification requests");
    throw error;
  }
}

// -----------------------------------------------------------------------------
// Get one
// -----------------------------------------------------------------------------

export async function getVerificationRequest({ id, user }) {
  const requestId = toIntId(id);
  const vr = await db.verificationRequest.findUnique({
    where: { id: requestId },
    include: {
      school: { select: { id: true, schoolName: true, adminId: true } },
      submittedBy: { select: { id: true, fullName: true, email: true } },
      reviewedBy: { select: { id: true, fullName: true, email: true } },
    },
  });
  if (!vr) throw new NotFoundError("Verification request not found");

// Parse documents JSON string back to array
const parsedVr = {
  ...vr,
  documents: vr.documents ? JSON.parse(vr.documents) : null,
};

  if (user.role === "MOE_OFFICER") return parsedVr;
  if (user.role === "SCHOOL_ADMIN" && vr.school.adminId === user.id) return parsedVr;
  throw new ForbiddenError("Not authorized to view this verification request");
}

// -----------------------------------------------------------------------------
// Review (MOE_OFFICER)
// -----------------------------------------------------------------------------

export async function reviewVerificationRequest({
  id,
  user,
  status,
  reviewNotes,
}) {
  if (user.role !== "MOE_OFFICER") {
    throw new ForbiddenError("Only MoE officers can review verification requests");
  }
  if (!["APPROVED", "REJECTED"].includes(status)) {
    throw new ValidationError("status must be APPROVED or REJECTED");
  }

  const requestId = toIntId(id);
  const vr = await db.verificationRequest.findUnique({
    where: { id: requestId },
    include: { school: { select: { id: true, schoolName: true } } },
  });
  if (!vr) throw new NotFoundError("Verification request not found");
  if (vr.status !== "PENDING") {
    throw new ConflictError(
      `Verification request already ${vr.status.toLowerCase()}`
    );
  }

// Parse documents JSON string back to array for the response
const parsedVr = {
  ...vr,
  documents: vr.documents ? JSON.parse(vr.documents) : null,
};

  const newSchoolStatus = status === "APPROVED" ? "VERIFIED" : "REJECTED";

  // Update both rows + notify in a single transaction so a partial failure
  // can't leave the school flipped without a corresponding decision row.
  const updated = await db.$transaction(async (tx) => {
    const updatedRequest = await tx.verificationRequest.update({
      where: { id: requestId },
      data: {
        status,
        reviewedById: user.id,
        reviewNotes: reviewNotes || null,
        reviewedAt: new Date(),
      },
    });

    await tx.school.update({
      where: { id: vr.schoolId },
      data: { verificationStatus: newSchoolStatus },
    });

    return updatedRequest;
  });

  // Notify the school admin who submitted. Best-effort — failure here
  // shouldn't roll back the verification decision.
  try {
    await createNotification({
      recipientId: vr.submittedById,
      recipientType: "SCHOOL_ADMIN",
      message:
        status === "APPROVED"
          ? `Your school "${vr.school.schoolName}" has been verified by the Ministry of Education.`
          : `Your verification request for "${vr.school.schoolName}" was rejected${
              reviewNotes ? `: ${reviewNotes}` : "."
            }`,
      sourceType: "SCHOOL",
      sourceId: vr.schoolId,
    });
  } catch {
    // intentional swallow — see comment above
  }

  // Return the updated request with parsed documents
  return {
    ...updated,
    documents: updated.documents ? JSON.parse(updated.documents) : null,
  };
}


export async function assignVerificationRequest(requestId) {  
  const request = await db.verificationRequest.findUnique({  
    where: { id: requestId },  
    include: { school: true }  
  });  
    
  if (!request) throw new NotFoundError("Verification request not found");  
    
  // Try to find MoE officer for the school's sub-city  
  const assignedOfficer = await db.moeOfficer.findFirst({  
    where: { subCity: request.school.subCity }  
  });  
    
  // Fallback to any available MoE officer if no sub-city match  
  if (!assignedOfficer) {  
    return db.moeOfficer.findFirst();  
  }  
    
  return assignedOfficer;  
}