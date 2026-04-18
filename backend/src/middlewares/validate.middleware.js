import { ZodError } from "zod";

/**
 * Request validation middleware powered by Zod.
 *
 * Usage:
 *   router.post("/", validate({ body: createSchemaZod }), handler);
 *   router.get("/:id", validate({ params: idParamsZod }), handler);
 *
 * Each segment (`body`, `params`, `query`) is optional. The parsed (and
 * therefore coerced / defaulted) value is written back onto `req` so that
 * downstream handlers see the clean data.
 *
 * Any validation failure is forwarded to the global error middleware as a
 * `ZodError`, which is mapped to a 400 response with field-level details.
 */
export function validate(schemas = {}) {
  return (req, res, next) => {
    try {
      if (schemas.body) {
        req.body = schemas.body.parse(req.body);
      }
      if (schemas.params) {
        req.params = schemas.params.parse(req.params);
      }
      if (schemas.query) {
        const parsed = schemas.query.parse(req.query);
        // Express 5 makes req.query a getter; mutate keys in place to stay compatible.
        for (const key of Object.keys(req.query)) {
          if (!(key in parsed)) delete req.query[key];
        }
        Object.assign(req.query, parsed);
      }
      next();
    } catch (err) {
      if (err instanceof ZodError) return next(err);
      next(err);
    }
  };
}
