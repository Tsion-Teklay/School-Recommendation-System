import { db } from "../config/db.js";
import {
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";

/**
 * Phase 4 — comparisons.
 *
 * Each `Comparison` row owns 2–5 `ComparisonSchool` join rows. We persist the
 * client's chosen metric list as a JSON string in `metricsUsed` (Text column)
 * so the saved comparison can be re-rendered later with the same columns,
 * even if the client app evolves its metric catalog.
 */

const DEFAULT_METRICS = [
  "curriculum",
  "tuitionFee",
  "rating",
  "facilities",
];

const SCHOOL_SELECT = {
  id: true,
  schoolName: true,
  curriculum: true,
  tuitionFee: true,
  rating: true,
  reviewCount: true,
  latitude: true,
  longitude: true,
  verificationStatus: true,
};

function decodeMetrics(raw) {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function shapeComparison(row) {
  return {
    id: row.id,
    parentId: row.parentId,
    metrics: decodeMetrics(row.metricsUsed),
    createdAt: row.createdAt,
    schools: row.comparisonSchools.map((cs) => cs.school),
  };
}

/**
 * Create a comparison for the calling parent.
 *
 * - Validates that all `schoolIds` exist (any unknown id → 404).
 * - The 2..5 cap is enforced in the schema layer; we re-check here defensively
 *   for non-HTTP callers and to surface a friendly error if something
 *   bypasses validation.
 * - Comparison + ComparisonSchool rows are written in a single transaction,
 *   so a partial failure can't leave orphan join rows behind.
 */
export async function createComparison(userId, { schoolIds, metrics }) {
  if (!Array.isArray(schoolIds) || schoolIds.length < 2 || schoolIds.length > 5) {
    throw new ValidationError("Pick between 2 and 5 schools");
  }
  const normalizedIds = [...new Set(schoolIds.map((n) => Number(n)))];
  if (normalizedIds.length !== schoolIds.length) {
    throw new ValidationError("Duplicate school ids are not allowed");
  }

  const found = await db.school.findMany({
    where: { id: { in: normalizedIds } },
    select: { id: true },
  });
  if (found.length !== normalizedIds.length) {
    throw new NotFoundError("One or more schools not found");
  }

  const metricsToSave = (metrics && metrics.length > 0 ? metrics : DEFAULT_METRICS);

  const created = await db.$transaction(async (tx) => {
    const comparison = await tx.comparison.create({
      data: {
        parentId: userId,
        metricsUsed: JSON.stringify(metricsToSave),
      },
    });

    await tx.comparisonSchool.createMany({
      data: normalizedIds.map((schoolId) => ({
        comparisonId: comparison.id,
        schoolId,
      })),
    });

    return tx.comparison.findUnique({
      where: { id: comparison.id },
      include: {
        comparisonSchools: {
          include: { school: { select: SCHOOL_SELECT } },
        },
      },
    });
  });

  return shapeComparison(created);
}

/** Paginated list of the calling parent's saved comparisons. */
export async function listMyComparisons(userId, { page = 1, limit = 10 } = {}) {
  const skip = (Number(page) - 1) * Number(limit);

  const [rows, total] = await Promise.all([
    db.comparison.findMany({
      where: { parentId: userId },
      include: {
        comparisonSchools: {
          include: { school: { select: SCHOOL_SELECT } },
        },
      },
      orderBy: { createdAt: "desc" },
      skip,
      take: Number(limit),
    }),
    db.comparison.count({ where: { parentId: userId } }),
  ]);

  return {
    data: rows.map(shapeComparison),
    meta: {
      total,
      page: Number(page),
      limit: Number(limit),
      totalPages: Math.ceil(total / Number(limit)),
    },
  };
}

/** Fetch one — only the owning parent can read. */
export async function getComparison(userId, comparisonId) {
  const row = await db.comparison.findUnique({
    where: { id: Number(comparisonId) },
    include: {
      comparisonSchools: {
        include: { school: { select: SCHOOL_SELECT } },
      },
    },
  });
  if (!row) throw new NotFoundError("Comparison not found");
  if (row.parentId !== userId) {
    throw new ForbiddenError("You don't own this comparison");
  }
  return shapeComparison(row);
}

/** Delete — owner-only; cascades the join rows in a transaction. */
export async function deleteComparison(userId, comparisonId) {
  const row = await db.comparison.findUnique({
    where: { id: Number(comparisonId) },
    select: { id: true, parentId: true },
  });
  if (!row) throw new NotFoundError("Comparison not found");
  if (row.parentId !== userId) {
    throw new ForbiddenError("You don't own this comparison");
  }

  await db.$transaction([
    db.comparisonSchool.deleteMany({ where: { comparisonId: row.id } }),
    db.comparison.delete({ where: { id: row.id } }),
  ]);

  return { message: "Comparison deleted" };
}
