import jwt from "jsonwebtoken";

export function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;

  // ✅ Check format: Bearer TOKEN
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing or invalid token" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = {
      id: decoded.userId,
      role: decoded.role,
    };

    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

/**
 * Soft auth for public routes that *can* personalize when the
 * caller is logged in (e.g. announcements list with `followedOnly=true`).
 *
 * Behaviour:
 *   - No `Authorization` header → fall through anonymous (`req.user` unset).
 *   - Valid Bearer token → populate `req.user` like `authenticate()` does.
 *   - Malformed or expired token → still fall through anonymous. We do NOT
 *     401 here, otherwise a stale token in the browser would break what is
 *     supposed to be a public endpoint.
 */
export function optionalAuthenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) return next();
  const token = authHeader.split(" ")[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = { id: decoded.userId, role: decoded.role };
  } catch {
    // Intentionally swallow — endpoint is public.
  }
  next();
}
