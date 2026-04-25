# School Recommendation System

Web platform that helps parents discover, compare and get personalized
recommendations for schools, backed by MoE verification, moderated reviews,
and a forum for community Q&A.

- **Backend**: Node.js + Express 5 (ESM) + Prisma 7 (MariaDB adapter) + JWT auth.
- **Frontend**: _coming in Phase 7_ (Next.js + Leaflet, PWA-first).
- **Status**: Phase 2 — schema hardening (rating aggregate, enum cleanup, Subscription + VerificationRequest models).

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

The server defaults to `http://localhost:5050` (port 5000 is reserved by Windows in many setups):

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

- `PORT` (default `5050`), `NODE_ENV` (default `development`),
  `LOG_LEVEL` (default `debug` in dev, `info` in prod, `silent` in test),
  `JWT_EXPIRES_IN` (default `1d`).
- `APP_URL` — base URL used in email verification / reset links (default `http://localhost:5050`).
- `SMTP_URL` — optional real SMTP endpoint. Leave empty in dev and Nodemailer
  will auto-create an [Ethereal](https://ethereal.email) test inbox on first
  send and log a preview URL to the console.
- `MAIL_FROM` — sender address on outbound mail (default `no-reply@schoolrec.local`).

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

## Phase 1 auth endpoints

Every new account is created unverified and **login is blocked until the
email is verified**. Dev email delivery goes to Ethereal — watch the server
log for the preview URL after every send.

| Method | Path                               | Auth   | Purpose                             |
| ------ | ---------------------------------- | ------ | ----------------------------------- |
| POST   | `/api/auth/register`               | —      | Create account + email verify link  |
| POST   | `/api/auth/login`                  | —      | Exchange credentials for JWT        |
| POST   | `/api/auth/verify-email`           | —      | Activate account with token         |
| POST   | `/api/auth/resend-verification`    | —      | Issue a fresh verification token    |
| POST   | `/api/auth/forgot-password`        | —      | Email a reset link                  |
| POST   | `/api/auth/reset-password`         | —      | Set a new password via reset token  |
| POST   | `/api/auth/change-password`        | JWT    | Swap password while logged in       |
| GET    | `/api/users/me`                    | JWT    | Current user's sanitized profile    |
| PUT    | `/api/users/me`                    | JWT    | Update `fullName` / `phone`         |
| POST   | `/api/users/me/deactivate`         | JWT    | Self-deactivate account             |

`resend-verification` and `forgot-password` always return **200** regardless
of whether the email is registered — this prevents account enumeration. Login
returns `{ code: "EMAIL_NOT_VERIFIED" }` for unverified accounts so the
frontend can prompt for resend.

---

## Phase 2 schema notes

No new endpoints; this phase tightens the data model.

- `School.rating` (`Decimal(3,2)`) and `School.reviewCount` (`Int`) are now
  cached on the school row. The review service recomputes both on every
  create / update / delete — the recommender (Phase 6) and the
  list/detail endpoints can read them directly instead of running
  `AVG(rating)` per request.
- `ReviewCategoryTag` enum gained **FACILITIES** and **AFFORDABILITY** to
  match the spec's review scenarios.
- `Notification.sourceType` is now an enum (`NotificationSourceType`:
  `ANNOUNCEMENT`, `REPORT`, `REVIEW`, `SCHOOL`, `SYSTEM`) instead of a
  free-form string. Existing rows are lowercased in the migration before
  the column type changes.
- New table `subscription` (`@@unique([parentId, schoolId])`) — the
  follow/subscribe model that Phase 4 will use to drive **targeted**
  announcement fan-out (replacing the current blast-all-parents pattern).
- New table `verification_request` (`status`: PENDING/APPROVED/REJECTED,
  `documents` JSON, audit fields `submittedAt` / `reviewedAt` /
  `reviewedById`) — backs the school verification workflow that lands in
  Phase 3 with the file-upload pipeline.

Neither subscription nor verification\_request has REST endpoints yet — only
the Prisma models so other phases can build on them without another
migration.

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
