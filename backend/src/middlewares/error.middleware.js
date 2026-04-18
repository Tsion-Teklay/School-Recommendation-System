import { ZodError } from "zod";
import { AppError } from "../utils/errors.js";
import { logger } from "../config/logger.js";

/**
 * Handler for unmatched routes. Mount after all routers.
 */
export function notFoundHandler(req, res, next) {
  res.status(404).json({
    error: "Not found",
    code: "NOT_FOUND",
    path: req.originalUrl,
  });
}

/**
 * Map Prisma errors to a friendly HTTP response.
 * We match by `err.code` (Prisma sets these on `PrismaClientKnownRequestError`)
 * without importing Prisma's error classes directly, to keep this layer decoupled.
 */
function mapPrismaError(err) {
  if (!err || typeof err !== "object" || !err.code) return null;
  switch (err.code) {
    case "P2002":
      return { statusCode: 409, code: "CONFLICT", message: "Resource already exists" };
    case "P2025":
      return { statusCode: 404, code: "NOT_FOUND", message: "Resource not found" };
    case "P2003":
      return { statusCode: 400, code: "VALIDATION_ERROR", message: "Invalid reference" };
    default:
      return null;
  }
}

/**
 * Global error middleware. Must be mounted LAST, after all routes.
 *
 *   app.use(errorHandler);
 */
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: "Invalid request",
      code: "VALIDATION_ERROR",
      details: err.issues.map((i) => ({
        path: i.path.join("."),
        message: i.message,
      })),
    });
  }

  if (err instanceof AppError) {
    const body = { error: err.message, code: err.code };
    if (err.details !== undefined) body.details = err.details;
    return res.status(err.statusCode).json(body);
  }

  const prismaMapped = mapPrismaError(err);
  if (prismaMapped) {
    return res.status(prismaMapped.statusCode).json({
      error: prismaMapped.message,
      code: prismaMapped.code,
    });
  }

  logger.error(
    {
      err: { message: err.message, stack: err.stack, name: err.name },
      path: req.originalUrl,
      method: req.method,
    },
    "Unhandled error"
  );

  res.status(500).json({
    error: "Something went wrong",
    code: "INTERNAL_ERROR",
  });
}
