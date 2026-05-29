/**
 * Application error hierarchy.
 *
 * Services and controllers should throw these instead of generic `Error`.
 * The global error middleware (see `middlewares/error.middleware.js`) maps
 * each subclass to the right HTTP status code and body shape, so callers
 * never need to set `res.status(...)` manually for domain errors.
 */
export class AppError extends Error {
  constructor(
    message,
    { statusCode = 500, code = "INTERNAL_ERROR", details } = {},
  ) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    if (details !== undefined) {
      this.details = details;
    }
  }
}

export class ValidationError extends AppError {
  constructor(message = "Validation failed. Please check your input.", details) {
    super(message, { statusCode: 400, code: "VALIDATION_ERROR", details });
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = "Unauthorized", code = "UNAUTHORIZED") {
    super(message, {
      statusCode: 401,
      code,
    });
  }
}

export class ForbiddenError extends AppError {
  constructor(message = "Forbidden") {
    super(message, { statusCode: 403, code: "FORBIDDEN" });
  }
}

export class NotFoundError extends AppError {
  constructor(message = "Not found") {
    super(message, { statusCode: 404, code: "NOT_FOUND" });
  }
}

export class ConflictError extends AppError {
  constructor(message = "Conflict") {
    super(message, { statusCode: 409, code: "CONFLICT" });
  }
}
