import axios from "axios";

// Match the base URL pattern directly from your documentation snippet
const TEXTBEE_BASE_URL =
  process.env.TEXTBEE_BASE_URL || "https://api.textbee.dev/api/v1";
const TEXTBEE_API_KEY = process.env.TEXTBEE_API_KEY;
const TEXTBEE_DEVICE_ID = process.env.TEXTBEE_DEVICE_ID;

export async function sendSMS({ to, message }) {
  if (!TEXTBEE_API_KEY || !TEXTBEE_DEVICE_ID) {
    throw new Error(
      "Missing TEXTBEE_API_KEY or TEXTBEE_DEVICE_ID in environment variables.",
    );
  }

  // 1. Clean up spacing, dashes, or formatting artifacts from input
  let cleanPhone = to.replace(/[\s\-()]+/g, "");

  // 2. Format explicitly to E.164 (+251...) to meet cloud router rules
  let formattedPhone = cleanPhone;
  if (formattedPhone.startsWith("0")) {
    formattedPhone = "+251" + formattedPhone.substring(1);
  } else if (formattedPhone.startsWith("251")) {
    formattedPhone = "+" + formattedPhone;
  } else if (!formattedPhone.startsWith("+")) {
    formattedPhone = "+251" + formattedPhone;
  }

  try {
    // 3. Exact payload match from your documentation snippet
    const payload = {
      recipients: [formattedPhone],
      message: message,
    };

    // 4. Exact endpoint structure mapping: /gateway/devices/${DEVICE_ID}/send-sms
    const targetUrl = `${TEXTBEE_BASE_URL}/gateway/devices/${TEXTBEE_DEVICE_ID}/send-sms`;

    console.log(`[SMS Cloud Gateway] Dispatching request to TextBee...`);

    const response = await axios.post(targetUrl, payload, {
      headers: {
        "Content-Type": "application/json",
        "x-api-key": TEXTBEE_API_KEY,
      },
      timeout: 10000,
    });

    console.log("TextBee cloud gateway response:", response.data);
    return response.data;
  } catch (error) {
    console.error("❌ TextBee Cloud dispatch failed.");
    console.error("Reason:", error.response?.data || error.message);
    throw error;
  }
}
