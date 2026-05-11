import { db } from "../config/db.js";
import { NotFoundError, ValidationError } from "../utils/errors.js";

/**
 * Upsert a parent's saved recommender preferences.
 *
 * The Parent row holds the home-pin (address + lat/lng); the Preference row
 * holds the criteria (budgets, curriculum, distance radius). Both can be
 * written in a single call from the preferences screen.
 *
 * If the Parent row doesn't exist yet (e.g. phone-only signup that never
 * filled in a home address), the caller MUST also supply address + lat + lng
 * so we can create the Parent row. Otherwise (existing parent), all home-pin
 * fields are optional updates.
 */
export async function upsertPreference(userId, data) {
  const parent = await db.parent.findUnique({ where: { userId } });

  const hasLocation =
    data.address != null && data.latitude != null && data.longitude != null;

  // Branch 1: brand-new parent — we must create the Parent row first, and to
  // do that we need a full home pin (all three fields are NOT NULL in the
  // schema). Communicate this requirement clearly to the client.
  if (!parent) {
    if (!hasLocation) {
      throw new ValidationError(
        "First-time setup requires address, latitude, and longitude"
      );
    }
    await db.parent.create({
      data: {
        userId,
        address: data.address,
        latitude: data.latitude,
        longitude: data.longitude,
      },
    });
  } else if (data.address != null || data.latitude != null || data.longitude != null) {
    // Branch 2: existing parent updating their home pin. Schema guarantees
    // lat/lng are paired; only update fields the client actually sent.
    await db.parent.update({
      where: { userId },
      data: {
        ...(data.address != null && { address: data.address }),
        ...(data.latitude != null && { latitude: data.latitude }),
        ...(data.longitude != null && { longitude: data.longitude }),
      },
    });
  }

  const preference = await db.preference.upsert({
    where: { parentId: userId },
    update: {
      minBudget: data.minBudget,
      maxBudget: data.maxBudget,
      curriculum: data.curriculum,
      distance: data.distance,
    },
    create: {
      parentId: userId,
      minBudget: data.minBudget,
      maxBudget: data.maxBudget,
      curriculum: data.curriculum,
      distance: data.distance,
    },
  });

  return preference;
}

/**
 * Read the parent's saved preferences AND home pin in one call so the
 * preferences screen can hydrate both sections without two round-trips.
 *
 * Returns null fields rather than 404'ing when the parent hasn't saved
 * anything yet — the screen needs an empty form, not an error toast.
 */
export async function getMyPreference(userId) {
  const [preference, parent] = await Promise.all([
    db.preference.findUnique({ where: { parentId: userId } }),
    db.parent.findUnique({ where: { userId } }),
  ]);

  return {
    minBudget: preference?.minBudget ?? null,
    maxBudget: preference?.maxBudget ?? null,
    curriculum: preference?.curriculum ?? null,
    distance: preference?.distance ?? null,
    address: parent?.address ?? null,
    latitude: parent?.latitude ?? null,
    longitude: parent?.longitude ?? null,
  };
}
