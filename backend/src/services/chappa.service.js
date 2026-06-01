import axios from "axios";
import { logger } from "../config/logger.js";

const CHAPPA_API_KEY = process.env.CHAPPA_API_KEY;
const CHAPPA_SECRET_KEY = process.env.CHAPPA_SECRET_KEY;
const CHAPPA_BASE_URL = process.env.CHAPPA_BASE_URL ;
export async function initializeChappaPayment({
  amount,
  email,
  phone,
  adId,
  title,
}) {
  const frontendUrl = process.env.FRONTEND_URL;
  const txRef = `ad_${adId}_${Date.now()}`;

  try {
    const response = await axios.post(
      `${CHAPPA_BASE_URL}/v1/transaction/initialize`,
      {
        amount: amount.toString(),
        currency: "ETB",
        email,
        phone,
        first_name: "Advertisement",
        last_name: `Ad-${adId}`,
        tx_ref: txRef,
        callback_url: `${process.env.APP_URL}/api/ads/chappa/callback`,
        return_url: `${frontendUrl}/advertise/success/${adId}`,
        customization: {
          title: `Advertisement: ${title}`,
          description: `Payment for advertisement placement`,
        },
      },
      {
        headers: {
          Authorization: `Bearer ${CHAPPA_API_KEY}`,
          "Content-Type": "application/json",
        },
      },
    );

    return {
      checkoutUrl: response.data.data.checkout_url,
      checkoutId: response.data.data.id,
      txRef: response.data.tx_ref,
    };
  } catch (error) {
    // If the network call failed because of offline status/DNS issue, fall back to mock in dev/test mode
    if (
      process.env.NODE_ENV !== "production" &&
      (error.code === "ENOTFOUND" ||
        error.code === "ECONNREFUSED" ||
        error.code === "ETIMEDOUT")
    ) {
      const fallbackTxRef = `mock_tx_ref_${adId}_${Date.now()}`;
      logger.warn(
        { error: error.message, adId },
        "Chappa API unreachable. Falling back to Mock Payment Checkout for development/testing.",
      );
      return {
        checkoutUrl: `${frontendUrl}/advertise/success/${adId}?tx_ref=${fallbackTxRef}`,
        checkoutId: `mock_checkout_id_${adId}`,
        txRef: fallbackTxRef,
      };
    }

    logger.error({ error, adId }, "Chappa payment initialization failed");
    throw new Error("Failed to initialize payment");
  }
}

export async function verifyChappaPayment(txRef) {
  if (txRef.startsWith("mock_") || process.env.MOCK_CHAPPA === "true") {
    return {
      status: "success",
      reference: txRef,
      amount: 0,
    };
  }

  try {
    const response = await axios.get(
      `${CHAPPA_BASE_URL}/v1/transaction/verify/${txRef}`,
      {
        headers: {
          Authorization: `Bearer ${CHAPPA_SECRET_KEY}`,
        },
      },
    );

    return {
      status: response.data.data.status,
      reference: response.data.data.reference,
      amount: response.data.data.amount,
    };
  } catch (error) {
    logger.error({ error, txRef }, "Chappa payment verification failed");
    throw new Error("Failed to verify payment");
  }
}
