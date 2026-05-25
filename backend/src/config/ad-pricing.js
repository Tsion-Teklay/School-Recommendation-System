/**
 * Advertisement pricing — daily ETB rate per placement type.
 * Override via env: AD_RATE_BANNER, AD_RATE_SIDEBAR, AD_RATE_FEATURED.
 */

const DEFAULT_RATES = {
  BANNER: 1000,
  SIDEBAR: 500,
  FEATURED: 1500,
};

function rateFromEnv(key, fallback) {
  const raw = process.env[key];
  if (raw == null || raw === "") return fallback;
  const n = Number(raw);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

export const AD_DAILY_RATES_ETB = {
  BANNER: rateFromEnv("AD_RATE_BANNER", DEFAULT_RATES.BANNER),
  SIDEBAR: rateFromEnv("AD_RATE_SIDEBAR", DEFAULT_RATES.SIDEBAR),
  FEATURED: rateFromEnv("AD_RATE_FEATURED", DEFAULT_RATES.FEATURED),
};

export const AD_PLACEMENT_TYPES = Object.keys(AD_DAILY_RATES_ETB);

/**
 * @param {"BANNER"|"SIDEBAR"|"FEATURED"} placementType
 * @param {number} durationDays
 * @returns {{ dailyRateEtb: number, durationDays: number, amountEtb: number }}
 */
export function calculateAdAmount(placementType, durationDays) {
  const dailyRateEtb = AD_DAILY_RATES_ETB[placementType];
  if (!dailyRateEtb) {
    throw new Error(`Unknown placement type: ${placementType}`);
  }
  const amountEtb = dailyRateEtb * durationDays;
  return { dailyRateEtb, durationDays, amountEtb };
}
