import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { registerVerifiedUser } from "./utils/auth.js";

let moderatorToken;
let adId;

async function cleanAdsOnly() {
  await db.advertisement.deleteMany();
  await db.payment.deleteMany();
}

beforeAll(async () => {
  await cleanAdsOnly();
  ({ token: moderatorToken } = await registerVerifiedUser({
    fullName: "Ad Moderator",
    email: `mod-ads-${Date.now()}@test.com`,
    phone: `0911${String(Date.now()).slice(-6)}`,
    role: "MODERATOR",
  }));
}, 30_000);

afterAll(async () => {
  await cleanAdsOnly();
  await db.$disconnect();
});

describe("Advertisement API", () => {
  it("returns public pricing", async () => {
    const res = await request(app).get("/api/ads/pricing");
    expect(res.statusCode).toBe(200);
    expect(res.body.pricing.rates.BANNER).toBe(1000);
  });

  it("creates a review-pending request without payment", async () => {
    const res = await request(app)
      .post("/api/ads/request")
      .field("companyName", "Bright Future Supplies")
      .field("contactEmail", "advertiser@test.com")
      .field("contactPhone", "0911223344")
      .field("title", "Back to School Sale")
      .field("targetUrl", "https://example.com/sale")
      .field("durationDays", "7")
      .field("placementType", "BANNER");

    expect(res.statusCode).toBe(201);
    expect(res.body.advertisement.status).toBe("PENDING_REVIEW");
    expect(res.body.advertisement.payment).toBeUndefined();
    expect(res.body.pricing.amountEtb).toBe(7000);

    adId = res.body.advertisement.id;
  });

  it("rejects payment before moderator approval", async () => {
    const res = await request(app).post(`/api/ads/${adId}/payment`).send({
      method: "TELEBIRR",
      transactionId: "TB-EARLY-1",
    });
    expect(res.statusCode).toBe(409);
  });

  it("moderator approves and emails payment instructions", async () => {
    const res = await request(app)
      .post(`/api/ads/admin/${adId}/approve`)
      .set("Authorization", `Bearer ${moderatorToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.advertisement.status).toBe("AWAITING_PAYMENT");
    expect(Number(res.body.advertisement.payment.amount)).toBe(7000);
    if (process.env.NODE_ENV === "test" && globalThis.__lastMail) {
      expect(globalThis.__lastMail.to).toBe("advertiser@test.com");
      expect(globalThis.__lastMail.text).toContain(`/advertise/pay/${adId}`);
    }
  });

  it("exposes pay details for approved ad", async () => {
    const res = await request(app).get(`/api/ads/pay/${adId}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.advertisement.status).toBe("AWAITING_PAYMENT");
  });

  it("activates ad after payment submission", async () => {
    const res = await request(app).post(`/api/ads/${adId}/payment`).send({
      method: "TELEBIRR",
      transactionId: "TB-TEST-123456",
    });

    expect(res.statusCode).toBe(200);
    expect(res.body.advertisement.status).toBe("ACTIVE");
    expect(res.body.advertisement.payment.status).toBe("COMPLETED");
    expect(res.body.advertisement.startDate).toBeTruthy();
    expect(res.body.advertisement.endDate).toBeTruthy();
  });

  it("lists active ads publicly", async () => {
    const res = await request(app)
      .get("/api/ads/active")
      .query({ placement: "BANNER" });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.some((a) => a.id === adId)).toBe(true);
  });
});
