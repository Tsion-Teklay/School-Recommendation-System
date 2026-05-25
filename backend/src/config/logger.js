import { randomUUID } from "node:crypto";
import pino from "pino";
import pinoHttp from "pino-http";

const isTest = process.env.NODE_ENV === "test";
const isProd = process.env.NODE_ENV === "production";

/**
 * Root logger. Pretty in dev, JSON in prod, silent in tests (so Jest output stays clean).
 */
export const logger = pino({
  level: process.env.LOG_LEVEL || (isTest ? "silent" : isProd ? "info" : "debug"),
  transport: !isProd && !isTest
    ? { target: "pino-pretty", options: { colorize: true, translateTime: "SYS:HH:MM:ss" } }
    : undefined,
});

/**
 * Request-scoped logger. Attaches a stable request id to every log line and
 * exposes it on `req.log`. Responses include `X-Request-Id` for correlation.
 */
export const httpLogger = pinoHttp({
  logger,
  genReqId: (req, res) => {
    const existing = req.headers["x-request-id"];
    const id = typeof existing === "string" && existing.length > 0 ? existing : randomUUID();
    res.setHeader("X-Request-Id", id);
    return id;
  },
  customLogLevel: (req, res, err) => {
    if (err || res.statusCode >= 500) return "error";
    if (res.statusCode >= 400) return "warn";
    return "info";
  },
  autoLogging: {
    ignore: (req) => req.url === "/api/healthz" || req.url === "/",
  },
});




