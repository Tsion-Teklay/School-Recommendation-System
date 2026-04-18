import swaggerJSDoc from "swagger-jsdoc";

/**
 * OpenAPI 3 definition built from JSDoc comments in route files.
 * Mount the generated spec behind `/api/docs` via `swagger-ui-express`.
 */
export const openApiSpec = swaggerJSDoc({
  definition: {
    openapi: "3.0.3",
    info: {
      title: "School Recommendation System API",
      version: "0.1.0",
      description:
        "Backend API for the School Recommendation System. Endpoints are organized by subsystem " +
        "(auth, schools, recommendations, preferences, favorites, reviews, announcements, reports, " +
        "notifications, analytics). Protected endpoints expect a Bearer JWT obtained from /api/auth/login.",
    },
    servers: [{ url: "http://localhost:5000", description: "Local dev" }],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
        },
      },
      schemas: {
        Error: {
          type: "object",
          properties: {
            error: { type: "string" },
            code: { type: "string" },
            details: {},
          },
          required: ["error", "code"],
        },
      },
    },
  },
  apis: ["./src/routes/*.js"],
});
