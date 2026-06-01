import axios from "axios";
import { logger } from "../config/logger.js";

const CHAPPA_API_KEY = process.env.CHAPPA_API_KEY;
const CHAPPA_SECRET_KEY = process.env.CHAPPA_SECRET_KEY;
const CHAPPA_BASE_URL = process.env.CHAPPA_BASE_URL || "https://api.chappa.co";

export async function initializeChappaPayment({
  amount,
  email,
  phone,
  adId,
  title,
}) {
  const frontendUrl = process.env.FRONTEND_URL || process.env.APP_URL || "http://localhost:3000";
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
      txRef: response.data.tx_ref || response.data.data?.tx_ref || txRef,
    };
  } catch (error) {
    logger.error(
      { error: error.response?.data || error.message, adId },
      "Chappa payment initialization failed"
    );
    throw new Error("Failed to initialize payment");
  }
}

export async function verifyChappaPayment(txRef) {
  try {
    const response = await axios.get(`${CHAPPA_BASE_URL}/v1/transaction/verify/${txRef}`, {
      headers: {
        Authorization: `Bearer ${CHAPPA_SECRET_KEY}`,
      },
    });

    return {
      status: response.data.status || response.data.data.status,
      reference: response.data.data.reference,
      amount: response.data.data.amount,
    };
  } catch (error) {
    logger.error(
      { error: error.response?.data || error.message, txRef },
      "Chappa payment verification failed"
    );
    throw new Error("Failed to verify payment");
  }
}
