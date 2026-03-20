export function authorizeRoles(...allowedRoles) {
  return (req, res, next) => {
    const user = req.user; // comes from JWT middleware
    if (!user) return res.status(401).json({ error: "Not authenticated" });

    if (!allowedRoles.includes(user.role)) {
      return res.status(403).json({ error: "Access denied" });
    }

    next();
  };
}