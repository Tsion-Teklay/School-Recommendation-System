import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import swaggerUi from "swagger-ui-express";

import { httpLogger } from "./config/logger.js";
import { openApiSpec } from "./config/openapi.js";
import {
  errorHandler,
  notFoundHandler,
} from "./middlewares/error.middleware.js";

const app = express();

// --- Security + infra middleware ---------------------------------------------
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use(httpLogger);

// Basic global rate limit to protect against brute-force + accidental loops.
// Tightened per-endpoint limits (e.g. /api/auth/login) land in Phase 1.
const globalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  limit: 300, // 300 req/min/IP — well above normal usage, blocks abuse
  standardHeaders: "draft-7",
  legacyHeaders: false,
});
if (process.env.NODE_ENV !== "test") {
  app.use(globalLimiter);
}

// --- Health + docs -----------------------------------------------------------
app.get("/", (req, res) => {
  res.send("API running");
});

app.get("/api/healthz", (req, res) => {
  res.json({ status: "ok" });
});

app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(openApiSpec));
app.get("/api/docs.json", (req, res) => res.json(openApiSpec));

// --- Feature routes ----------------------------------------------------------
app.use("/api/auth", (await import("./routes/auth.routes.js")).default);
app.use("/api/schools", (await import("./routes/school.routes.js")).default);
app.use(
  "/api/recommendations",
  (await import("./routes/recommendation.routes.js")).default
);
app.use(
  "/api/preferences",
  (await import("./routes/preference.routes.js")).default
);
app.use(
  "/api/favorites",
  (await import("./routes/favorite.routes.js")).default
);
app.use("/api/reviews", (await import("./routes/review.routes.js")).default);
app.use(
  "/api/announcements",
  (await import("./routes/announcement.routes.js")).default
);
app.use("/api/reports", (await import("./routes/report.routes.js")).default);
app.use(
  "/api/notifications",
  (await import("./routes/notification.routes.js")).default
);
app.use(
  "/api/analytics",
  (await import("./routes/analytics.routes.js")).default
);

// Dev-only utility routes — never mount in production.
if (process.env.NODE_ENV !== "production") {
  app.use("/api/test", (await import("./routes/test.routes.js")).default);
}

// --- Error handling (must be last) -------------------------------------------
app.use(notFoundHandler);
app.use(errorHandler);

export default app;
