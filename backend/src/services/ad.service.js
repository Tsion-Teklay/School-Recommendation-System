import { db } from "../config/db.js";
import { calculateAdAmount, AD_DAILY_RATES_ETB } from "../config/ad-pricing.js";
import { sendAdPaymentInstructionsEmail } from "./ad-email.service.js";
import { logger } from "../config/logger.js";
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";

function toIntId(id, label = "id") {
  const parsed = Number(id);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new ValidationError(`Invalid ${label}`);
  }
  return parsed;
}

function pricingForAd(ad) {
  const p = calculateAdAmount(ad.placementType, ad.durationDays);
  return {
    placementType: ad.placementType,
    durationDays: ad.durationDays,
    dailyRateEtb: p.dailyRateEtb,
    amountEtb: ad.payment ? Number(ad.payment.amount) : p.amountEtb,
    currency: "ETB",
  };
}

function serializeAd(ad) {
  if (!ad) return null;
  return {
    ...ad,
    amount: ad.payment?.amount != null ? Number(ad.payment.amount) : undefined,
    payment: ad.payment
      ? {
          ...ad.payment,
          amount: Number(ad.payment.amount),
        }
      : undefined,
  };
}

const publicAdSelect = {
  id: true,
  title: true,
  description: true,
  imageUrl: true,
  targetUrl: true,
  placementType: true,
  companyName: true,
  startDate: true,
  endDate: true,
  impressions: true,
  clicks: true,
};

function activeAdWhere(extra = {}) {
  const now = new Date();
  return {
    status: "ACTIVE",
    payment: { status: "COMPLETED" },
    startDate: { lte: now },
    endDate: { gte: now },
    ...extra,
  };
}

// -----------------------------------------------------------------------------
// Public — request (no payment until moderator approves)
// -----------------------------------------------------------------------------

export async function createAdRequest({
  companyName,
  contactEmail,
  contactPhone,
  title,
  description,
  targetUrl,
  durationDays,
  placementType,
  imageUrl,
}) {
  const pricing = calculateAdAmount(placementType, durationDays);

  const ad = await db.advertisement.create({
    data: {
      companyName,
      contactEmail: contactEmail.toLowerCase(),
      contactPhone,
      title,
      description: description || null,
      imageUrl: imageUrl || null,
      targetUrl,
      durationDays,
      placementType,
      status: "PENDING_REVIEW",
    },
  });

  return {
    advertisement: serializeAd(ad),
    pricing: {
      placementType,
      durationDays: pricing.durationDays,
      dailyRateEtb: pricing.dailyRateEtb,
      amountEtb: pricing.amountEtb,
      currency: "ETB",
    },
    message:
      "Advertisement request submitted. You will receive an email with payment instructions after a moderator approves your ad.",
  };
}

export async function getAdRequestStatus(adId) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });
  if (!ad) throw new NotFoundError("Advertisement request not found");

  return {
    advertisement: serializeAd(ad),
    pricing: pricingForAd(ad),
  };
}

/** Public payment page — only ads awaiting payment after moderator approval. */
export async function getAdForPayment(adId) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });
  if (!ad) throw new NotFoundError("Advertisement not found");
  if (ad.status !== "AWAITING_PAYMENT") {
    throw new ConflictError(
      "This advertisement is not awaiting payment. Check your email for the correct link or contact support.",
    );
  }
  if (!ad.payment) {
    throw new ValidationError("Payment record missing for this advertisement");
  }

  return {
    advertisement: serializeAd(ad),
    pricing: pricingForAd(ad),
  };
}

export async function submitAdPayment({ adId, method, transactionId }) {
  const id = toIntId(adId, "adId");

  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });
  if (!ad) throw new NotFoundError("Advertisement request not found");
  if (ad.status !== "AWAITING_PAYMENT") {
    throw new ConflictError(
      "Payment is not open for this advertisement. Wait for moderator approval or check your email.",
    );
  }
  if (!ad.paymentId || !ad.payment) {
    throw new ValidationError("No payment record linked to this advertisement");
  }

  const duplicateTxn = await db.payment.findFirst({
    where: { transactionId, id: { not: ad.paymentId } },
  });
  if (duplicateTxn) {
    throw new ConflictError("Transaction ID is already registered");
  }

  const now = new Date();
  const endDate = new Date(now);
  endDate.setDate(endDate.getDate() + ad.durationDays);

  const [payment, updatedAd] = await db.$transaction([
    db.payment.update({
      where: { id: ad.paymentId },
      data: { method, transactionId, status: "COMPLETED" },
    }),
    db.advertisement.update({
      where: { id },
      data: {
        status: "ACTIVE",
        startDate: now,
        endDate,
      },
      include: { payment: true },
    }),
  ]);

  return {
    advertisement: serializeAd({ ...updatedAd, payment }),
    message:
      "Payment recorded. Your advertisement is now live for the selected duration.",
  };
}

// -----------------------------------------------------------------------------
// Public — display + analytics
// -----------------------------------------------------------------------------

export async function listActiveAds({ placement, limit = 5 }) {
  const where = activeAdWhere(placement ? { placementType: placement } : {});

  const ads = await db.advertisement.findMany({
    where,
    take: limit,
    orderBy: { approvedAt: "desc" },
    select: publicAdSelect,
  });

  return { data: ads };
}

export async function recordImpression(adId) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findFirst({
    where: { id, ...activeAdWhere() },
  });
  if (!ad) throw new NotFoundError("Active advertisement not found");

  await db.advertisement.update({
    where: { id },
    data: { impressions: { increment: 1 } },
  });
  return { recorded: true };
}

export async function recordClick(adId) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findFirst({
    where: { id, ...activeAdWhere() },
  });
  if (!ad) throw new NotFoundError("Active advertisement not found");

  await db.advertisement.update({
    where: { id },
    data: { clicks: { increment: 1 } },
  });
  return { recorded: true, targetUrl: ad.targetUrl };
}

// -----------------------------------------------------------------------------
// Admin (MODERATOR) — content review, then email payment link
// -----------------------------------------------------------------------------

export async function listAdsForAdmin({ query }) {
  const { status, page = 1, limit = 10 } = query;
  const where = {};
  if (status) where.status = status;
  else {
    where.status = {
      in: [
        "PENDING_REVIEW",
        "AWAITING_PAYMENT",
        "ACTIVE",
        "REJECTED",
        "EXPIRED",
      ],
    };
  }

  const skip = (Number(page) - 1) * Number(limit);
  const [data, total] = await Promise.all([
    db.advertisement.findMany({
      where,
      skip,
      take: Number(limit),
      orderBy: { createdAt: "desc" },
      include: {
        payment: true,
        approver: { select: { id: true, fullName: true, email: true } },
      },
    }),
    db.advertisement.count({ where }),
  ]);

  return {
    data: data.map(serializeAd),
    meta: {
      total,
      page: Number(page),
      limit: Number(limit),
      totalPages: Math.ceil(total / Number(limit)) || 1,
    },
  };
}

/** Approve ad content → create payment, email pay link (does not go live yet). */
export async function approveAd({ adId, userId }) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });
  if (!ad) throw new NotFoundError("Advertisement not found");
  if (ad.status !== "PENDING_REVIEW") {
    throw new ConflictError("Only ads pending review can be approved");
  }

  const pricing = calculateAdAmount(ad.placementType, ad.durationDays);
  const now = new Date();

  const payment = await db.payment.create({
    data: {
      amount: pricing.amountEtb,
      currency: "ETB",
      status: "PENDING",
    },
  });

  const updated = await db.advertisement.update({
    where: { id },
    data: {
      status: "AWAITING_PAYMENT",
      paymentId: payment.id,
      approvedBy: userId,
      approvedAt: now,
      rejectReason: null,
    },
    include: {
      payment: true,
      approver: { select: { id: true, fullName: true } },
    },
  });

  try {
    await sendAdPaymentInstructionsEmail({
      to: ad.contactEmail,
      adId: id,
      paymentId: payment.id,
      title: ad.title,
      amountEtb: pricing.amountEtb,
      durationDays: ad.durationDays,
      placementType: ad.placementType,
    });
  } catch (err) {
    // Email failures should not break the approval flow — ad is already
    // marked AWAITING_PAYMENT and has a payment record. Log and continue.
    logger.error(
      { err, adId: id, to: ad.contactEmail },
      "Failed to send ad payment email",
    );
  }

  return serializeAd(updated);
}

export async function rejectAd({ adId, userId, reason }) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });
  if (!ad) throw new NotFoundError("Advertisement not found");
  if (ad.status !== "PENDING_REVIEW" && ad.status !== "AWAITING_PAYMENT") {
    throw new ConflictError("This advertisement can no longer be rejected");
  }

  if (ad.paymentId) {
    await db.payment.update({
      where: { id: ad.paymentId },
      data: { status: "FAILED" },
    });
  }

  const updated = await db.advertisement.update({
    where: { id },
    data: {
      status: "REJECTED",
      approvedBy: userId,
      approvedAt: new Date(),
      rejectReason: reason || null,
    },
    include: { payment: true },
  });

  return serializeAd(updated);
}

export async function getAdPricingInfo() {
  return {
    currency: "ETB",
    rates: AD_DAILY_RATES_ETB,
    example: {
      placementType: "BANNER",
      durationDays: 7,
      ...calculateAdAmount("BANNER", 7),
    },
  };
}

export async function getAdRevenueAnalytics({ query }) {
  const { page = 1, limit = 10 } = query;
  const skip = (Number(page) - 1) * Number(limit);

  const [completedPayments, totalRevenue, activeCount, pendingReview] =
    await Promise.all([
      db.payment.findMany({
        where: { status: "COMPLETED" },
        skip,
        take: Number(limit),
        orderBy: { updatedAt: "desc" },
        include: {
          advertisement: {
            select: {
              id: true,
              title: true,
              companyName: true,
              impressions: true,
              clicks: true,
              placementType: true,
              status: true,
            },
          },
        },
      }),
      db.payment.aggregate({
        where: { status: "COMPLETED" },
        _sum: { amount: true },
      }),
      db.advertisement.count({ where: activeAdWhere() }),
      db.advertisement.count({ where: { status: "PENDING_REVIEW" } }),
    ]);

  const totalImpressions = await db.advertisement.aggregate({
    _sum: { impressions: true, clicks: true },
  });

  return {
    summary: {
      totalRevenueEtb: Number(totalRevenue._sum.amount || 0),
      activeAds: activeCount,
      pendingReview,
      totalImpressions: totalImpressions._sum.impressions || 0,
      totalClicks: totalImpressions._sum.clicks || 0,
    },
    payments: completedPayments.map((p) => ({
      ...p,
      amount: Number(p.amount),
      advertisement: p.advertisement,
    })),
    meta: { page: Number(page), limit: Number(limit) },
  };
}

export async function expireDueAdvertisements() {
  const now = new Date();
  const result = await db.advertisement.updateMany({
    where: {
      status: "ACTIVE",
      endDate: { lt: now },
    },
    data: { status: "EXPIRED" },
  });
  return { expiredCount: result.count };
}

export function assertModerator(user) {
  if (!user || user.role !== "MODERATOR") {
    throw new ForbiddenError("Moderator access required");
  }
}
