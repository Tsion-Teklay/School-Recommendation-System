import { ValidationError } from "../utils/errors.js";
import { logger } from "../config/logger.js";

/**
 * Phase 5 — pluggable content moderation.
 *
 * Anything user-generated (review.comment, announcement.content,
 * forum.content, …) flows through `validateContent(text)` before it hits
 * the database. The default implementation is a keyword blocklist driven by
 * the `CONTENT_BLOCKLIST` env var (comma-separated). The interface is
 * intentionally narrow — `{ validate(text): { ok, reason? } }` — so a future
 * phase can swap in OpenAI moderations / Perspective / etc. without
 * touching any caller.
 *
 * Failure mode: `ValidationError` with code `CONTENT_REJECTED` and a
 * `reason` field naming the offending term, so the frontend can show a
 * specific message instead of a generic 400.
 */

const DEFAULT_BLOCKLIST = [
  // Keep this list intentionally small + boring. The spec only requires a
  // pluggable validator; the keyword set is a placeholder until Phase 9
  // wires in a real moderation provider.
  "fuck",
  "shit",
  "bitch",
  "asshole",
  "idiot",
  "stupid",
  "spam",
];

function loadBlocklist() {
  const fromEnv = (process.env.CONTENT_BLOCKLIST || "")
    .split(",")
    .map((w) => w.trim().toLowerCase())
    .filter(Boolean);
  // Env list fully overrides the default when set, but if unset we fall back
  // to the boring default so dev environments still have *some* signal.
  return fromEnv.length > 0 ? fromEnv : DEFAULT_BLOCKLIST;
}

function buildKeywordValidator() {
  const blocklist = loadBlocklist();
  return {
    validate(text) {
      if (typeof text !== "string" || text.length === 0) {
        return { ok: true };
      }
      const lower = text.toLowerCase();
      for (const term of blocklist) {
        // word-boundary-ish check: surround with non-word chars or string ends
        const pattern = new RegExp(`(^|[^\\w])${escapeRegex(term)}([^\\w]|$)`, "i");
        if (pattern.test(lower)) {
          return { ok: false, reason: `blocked term: ${term}` };
        }
      }
      return { ok: true };
    },
  };
}

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

let activeValidator = buildKeywordValidator();

/**
 * Test seam — swap the validator implementation. Tests can call this to
 * inject a stricter/laxer validator without monkey-patching the module.
 */
export function setContentValidator(validator) {
  activeValidator = validator;
}

/**
 * Reload the keyword validator from the current `CONTENT_BLOCKLIST` env.
 * Useful if env changes at runtime; mostly used by tests.
 */
export function reloadDefaultValidator() {
  activeValidator = buildKeywordValidator();
}

/**
 * Validate a piece of user-generated content. Throws `ValidationError`
 * (code: CONTENT_REJECTED) on failure; returns silently on success.
 *
 * The `field` arg is included in the error details so callers don't have to
 * thread it through themselves — handy when a payload has multiple text
 * fields and the API consumer needs to know which one failed.
 */
export function validateContent(text, { field = "content" } = {}) {
  const result = activeValidator.validate(text);
  if (!result.ok) {
    logger.info(
      { field, reason: result.reason },
      "Content rejected by moderation"
    );
    const err = new ValidationError("Content rejected by moderation", {
      field,
      reason: result.reason,
    });
    // Override the default code so the frontend can branch on it.
    err.code = "CONTENT_REJECTED";
    throw err;
  }
}
