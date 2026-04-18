# School Recommendation System

Web platform that helps parents discover, compare and get personalized
recommendations for schools, backed by MoE verification, moderated reviews,
and a forum for community Q&A.

- **Backend**: Node.js + Express 5 (ESM) + Prisma 7 (MariaDB adapter) + JWT auth.
- **Frontend**: _coming in Phase 7_ (Next.js + Leaflet, PWA-first).
- **Status**: Phase 0 — foundation hygiene.

Active development happens on `develop`; `main` only receives the final release.

---

## Architecture decisions (Phase 0)

All choices are free, offline-friendly, and easy to swap for a hosted
alternative later when we deploy.

| Area               | Choice                                                       |
| ------------------ | ------------------------------------------------------------ |
| Email              | Nodemailer + Ethereal (local dev fake SMTP) — Phase 1        |
| SMS verification   | Skipped (email-only verification is enough for the defense)  |
| File storage       | Local disk under `backend/uploads/` (gitignored) — Phase 3   |
| Map provider       | Leaflet + OpenStreetMap tiles (no API key)                   |
| Moderation         | Keyword blocklist with pluggable `ContentValidator` — Phase 5 |
| Recommender        | Content-based v1 (weighted score, no ML) — Phase 6           |
| Mobile             | PWA (Next.js manifest + service worker) — Phase 10           |
| Deployment         | Deferred; Render (backend) + Vercel (frontend) when ready    |

---

## Prerequisites

- **Node.js 20+** (check with `node -v`)
- **MariaDB 10.6+** or **MySQL 8+** running locally
  (Docker works fine — `docker run -p 3306:3306 -e MARIADB_ROOT_PASSWORD=root mariadb:10.11`)

---

## Getting started

```bash
# 1. Clone + enter
git clone <this-repo>
cd School-Recommendation-System

# 2. Install backend deps
cd backend
npm install

# 3. Configure environment
cp .env.example .env
# …then edit .env to point at your local MariaDB and set JWT_SECRET.

# 4. Run Prisma migrations
npx prisma migrate dev

# 5. Start the dev server (auto-reloads on file changes)
npm run dev
```

The server defaults to `http://localhost:5000`:

- `GET /` → `API running`
- `GET /api/healthz` → `{ "status": "ok" }`
- `GET /api/docs` → interactive OpenAPI/Swagger UI
- `GET /api/docs.json` → raw OpenAPI 3 spec

Dev-only utility routes live under `/api/test/*` and are **only mounted
when `NODE_ENV !== "production"`**.

---

## Environment variables

See [`backend/.env.example`](backend/.env.example) for the full list. The
required ones in dev are:

| Variable           | Purpose                                  |
| ------------------ | ---------------------------------------- |
| `JWT_SECRET`       | Signing key for access tokens            |
| `DATABASE_HOST`    | MariaDB host (used by the Prisma adapter) |
| `DATABASE_USER`    | MariaDB user                             |
| `DATABASE_PASSWORD`| MariaDB password                         |
| `DATABASE_NAME`    | MariaDB database name                    |
| `DATABASE_URL`     | Full connection string (used by `prisma` CLI) |

Optional:

- `PORT` (default `5000`), `NODE_ENV` (default `development`),
  `LOG_LEVEL` (default `debug` in dev, `info` in prod, `silent` in test),
  `JWT_EXPIRES_IN` (default `1d`).

---

## Common scripts

All scripts run from `backend/`:

```bash
npm run dev                  # start Express with watch mode
npm test                     # run Jest + Supertest suites (hits a live DB)
npx prisma migrate dev       # create a new migration from schema changes
npx prisma migrate deploy    # apply pending migrations
npx prisma studio            # open the Prisma data browser
```

---

## Project layout

```
backend/
  prisma/                 Prisma schema + migrations
  src/
    app.js                Express app (middleware stack + routes)
    server.js             Process entry (reads .env, starts listener)
    config/               db.js, logger.js, openapi.js
    middlewares/          auth, role, validate, async, error
    routes/               One router per subsystem (REST)
    controllers/          Thin; delegate to services
    services/             Business rules, data access via Prisma
    schemas/              Zod request-validation schemas
    utils/errors.js       AppError hierarchy (Not/Forbidden/Conflict/Validation)
    tests/                Jest + Supertest integration tests
frontend/                 (empty until Phase 7)
```

---

## Error handling & validation

- All services throw typed errors from `utils/errors.js`
  (`NotFoundError`, `ForbiddenError`, `ConflictError`, `ValidationError`,
  `UnauthorizedError`). The global error middleware maps each to the right
  HTTP status code.
- Controllers use `asyncHandler(...)` — no manual try/catch.
- All request bodies/params/queries are validated at the route level with
  Zod schemas defined under `src/schemas/`.
- Every response has a `X-Request-Id` header and every log line carries the
  same id for easy correlation.

---

## RBAC (enforced at the route layer)

| Role           | Key permissions (non-exhaustive)                          |
| -------------- | --------------------------------------------------------- |
| `PARENT`       | reviews, favorites, preferences, **recommendations**      |
| `SCHOOL_ADMIN` | own school CRUD, school-level announcements, analytics write |
| `MOE_OFFICER`  | ministry announcements, analytics write, **dashboard**    |
| `MODERATOR`    | reports queue + actions (cannot submit reports)           |

See `src/middlewares/role.middleware.js` and each route file's JSDoc.

---

## Contributing / git workflow

- Branch off `develop` (never `main`).
- Branch naming: `feat/<area>-<short-desc>` or `fix/<area>-<short-desc>`.
- One phase = one or more PRs into `develop`. `develop → main` happens
  exactly once, at release time before defense.
- Keep PRs small enough that CI runs in under a few minutes.

---

## License

TBD.
