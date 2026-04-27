# School Recommendation System

Web platform that helps parents discover, compare and get personalized
recommendations for schools, backed by MoE verification, moderated reviews,
and a forum for community Q&A.

- **Backend**: Node.js + Express 5 (ESM) + Prisma 7 (MariaDB adapter) + JWT auth.
- **Frontend**: _coming in Phase 7_ (Next.js + Leaflet, PWA-first).
- **Status**: Phase 4 — comparisons, follow/subscribe, targeted announcement fan-out, proximity search.

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

## Phase 3 verification + uploads

School admins can now submit accreditation/license documents to the Ministry
of Education for review. MoE officers approve or reject; an approval flips
the school's `verificationStatus` to `VERIFIED` and notifies the admin.

| Method | Path                                                         | Auth                | Purpose                              |
| ------ | ------------------------------------------------------------ | ------------------- | ------------------------------------ |
| POST   | `/api/schools/:schoolId/verification-requests`               | SCHOOL_ADMIN (owner) | Submit docs (multipart, up to 5)     |
| GET    | `/api/verification-requests`                                 | MOE_OFFICER, SCHOOL_ADMIN | List (MoE: all; admin: own)     |
| GET    | `/api/verification-requests/:id`                             | MOE_OFFICER, SCHOOL_ADMIN owner | View one                  |
| POST   | `/api/verification-requests/:id/review`                      | MOE_OFFICER         | Approve/reject + reviewNotes         |

**Upload pipeline** (`src/config/uploads.js`):

- Powered by [multer](https://www.npmjs.com/package/multer); files written to
  `UPLOAD_DIR/verification/<timestamp-rand>.<ext>` and served read-only at
  `/uploads/...` via `express.static`.
- Whitelist: `application/pdf`, `image/png`, `image/jpeg`. Anything else →
  `400 VALIDATION_ERROR` ("Unsupported file type").
- Per-file cap: `UPLOAD_MAX_SIZE_BYTES` (default **10 MB**). Multer's
  `LIMIT_FILE_SIZE` is wrapped into a `ValidationError` so callers see the
  same error envelope as Zod failures.
- One pending request per school; resubmit only after a rejection.
- Phase 9 swaps this single module for an S3 / Backblaze adapter — call sites
  use `relativeUrl(file)` and never raw paths.

---

## Phase 4 endpoints

### Follow / Subscribe

| Method | Path                              | Auth   | Purpose                                |
| ------ | --------------------------------- | ------ | -------------------------------------- |
| POST   | `/api/schools/:schoolId/follow`   | PARENT | Subscribe to a school's announcements  |
| DELETE | `/api/schools/:schoolId/follow`   | PARENT | Unsubscribe                            |
| GET    | `/api/me/follows`                 | PARENT | Paginated list of followed schools     |

`GET /api/schools/:id` now also returns `followerCount` so the UI doesn't
need a second roundtrip.

### Comparisons

| Method | Path                       | Auth   | Purpose                                          |
| ------ | -------------------------- | ------ | ------------------------------------------------ |
| POST   | `/api/comparisons`         | PARENT | Compare 2–5 schools (`{ schoolIds, metrics? }`)  |
| GET    | `/api/comparisons`         | PARENT | List the caller's saved comparisons              |
| GET    | `/api/comparisons/:id`     | PARENT | Side-by-side detail (owner only)                 |
| DELETE | `/api/comparisons/:id`     | PARENT | Delete a saved comparison                        |

Validation enforces the 2–5-school cap (UC07) and rejects duplicate ids at
the schema layer; the service double-checks all referenced schools exist.

### Targeted announcement fan-out

The blast-all-parents fan-out from earlier phases is replaced by a
publisher-aware notification step:

- `POST /api/announcements/school` (SCHOOL_ADMIN) **requires** `schoolId` and
  the caller must own that school. Subscribers of that school each get one
  `Notification` row.
- `POST /api/announcements/moe` (MOE_OFFICER) keeps the broadcast behaviour:
  every PARENT account receives a notification.
- The legacy `POST /api/announcements` endpoint is preserved for backward
  compatibility — its publisher type is inferred from the caller's role.

A new optional `Announcement.schoolId` foreign key links school-scoped
posts back to the school, indexed for the fan-out query.

### Proximity search

`GET /api/schools` now accepts:

- `near=lat,lng` — origin point (latitude in `[-90, 90]`, longitude in `[-180, 180]`).
- `radiusKm=N` — radius in kilometres, positive number (default `25`).

Implementation: a bounding-box pre-filter at the DB (`latitude`/`longitude`
range scans) followed by an exact Haversine distance check in JS for the
survivors. Results are sorted ascending by `distanceKm`, which is also
exposed on each row in the response. Composes with the existing `search`,
`curriculum`, `minFee`, `maxFee`, `page`, `limit` filters.

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
