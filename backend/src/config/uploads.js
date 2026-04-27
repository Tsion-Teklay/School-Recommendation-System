import { mkdirSync } from "fs";
import path from "path";
import crypto from "crypto";
import multer from "multer";

import { ValidationError } from "../utils/errors.js";

/**
 * Local-disk upload pipeline (Phase 3).
 *
 * Architectural decision per the roadmap: filesystem storage in dev — no
 * cloud account required. Phase 9 swaps this single module for an S3
 * adapter (Backblaze B2 / Spaces) without touching call sites; that's why
 * the public API here exposes `relativeUrl(req.file)` and never raw paths.
 */

export const UPLOAD_DIR = path.resolve(
  process.env.UPLOAD_DIR ||
    path.join(process.cwd(), "uploads")
);

// Default: 10 MB. Override with UPLOAD_MAX_SIZE_BYTES.
export const UPLOAD_MAX_SIZE_BYTES = Number(
  process.env.UPLOAD_MAX_SIZE_BYTES || 10 * 1024 * 1024
);

// Subdirectory used by the verification workflow. Other features (facility
// images, announcement attachments) will get their own subdirs in later phases.
const VERIFICATION_SUBDIR = "verification";

// MIME whitelist for verification document uploads — accreditation papers
// are usually PDFs or photographed paper documents.
const VERIFICATION_MIME_WHITELIST = new Set([
  "application/pdf",
  "image/png",
  "image/jpeg",
  "image/jpg",
]);

mkdirSync(path.join(UPLOAD_DIR, VERIFICATION_SUBDIR), { recursive: true });

function safeFilename(originalName) {
  const ext = path.extname(originalName).toLowerCase().replace(/[^.a-z0-9]/g, "");
  const stamp = Date.now();
  const rand = crypto.randomBytes(8).toString("hex");
  return `${stamp}-${rand}${ext}`;
}

const verificationStorage = multer.diskStorage({
  destination(req, file, cb) {
    cb(null, path.join(UPLOAD_DIR, VERIFICATION_SUBDIR));
  },
  filename(req, file, cb) {
    cb(null, safeFilename(file.originalname));
  },
});

const verificationUploader = multer({
  storage: verificationStorage,
  limits: { fileSize: UPLOAD_MAX_SIZE_BYTES },
  fileFilter(req, file, cb) {
    if (!VERIFICATION_MIME_WHITELIST.has(file.mimetype)) {
      cb(
        new ValidationError(
          `Unsupported file type: ${file.mimetype}. Allowed: PDF, PNG, JPEG.`
        )
      );
      return;
    }
    cb(null, true);
  },
});

/**
 * Translates multer's own errors (file too big, too many files) into our
 * `ValidationError` so the global error middleware emits a consistent
 * `{code: "VALIDATION_ERROR"}` shape.
 */
function wrapMulter(middleware) {
  return (req, res, next) => {
    middleware(req, res, (err) => {
      if (!err) return next();
      if (err instanceof multer.MulterError) {
        const map = {
          LIMIT_FILE_SIZE: `File too large (max ${UPLOAD_MAX_SIZE_BYTES} bytes)`,
          LIMIT_FILE_COUNT: "Too many files in this request",
          LIMIT_UNEXPECTED_FILE: `Unexpected field: ${err.field}`,
        };
        return next(new ValidationError(map[err.code] || err.message));
      }
      return next(err);
    });
  };
}

/** Up-to-5 verification documents under field `documents`. */
export const verificationDocumentsUpload = wrapMulter(
  verificationUploader.array("documents", 5)
);

/**
 * Build the public URL the API will return for a stored file. Always
 * relative — the frontend resolves it against `APP_URL`.
 */
export function relativeUrl(file) {
  if (!file) return null;
  // file.path is absolute; strip the upload-dir prefix and prepend `/uploads`.
  const rel = path.relative(UPLOAD_DIR, file.path).split(path.sep).join("/");
  return `/uploads/${rel}`;
}
