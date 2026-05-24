import axios from "axios";

const SMS_BASE_URL =
  process.env.SMS_ETHIOPIA_BASE_URL || "https://smsethiopia.et/api";

const SMS_API_KEY = process.env.SMS_ETHIOPIA_API_KEY;

export async function sendSMS({ to, message }) {
  if (!SMS_API_KEY) {
    throw new Error("SMS Ethiopia API key missing");
  }

  let formattedPhone = to.replace(/\s+/g, "");

  // 0912345678 -> 251912345678
  if (formattedPhone.startsWith("09")) {
    formattedPhone = "251" + formattedPhone.substring(1);
  }

  // +251912345678 -> 251912345678
  if (formattedPhone.startsWith("+251")) {
    formattedPhone = formattedPhone.substring(1);
  }

  try {
    const payload = {
      msisdn: formattedPhone,
      text: message,
    };

    console.log("Sending SMS payload:", payload);

    const response = await axios.post(`${SMS_BASE_URL}/sms/send`, payload, {
      headers: {
        KEY: SMS_API_KEY,
        "Content-Type": "application/json",
      },
    });

    console.log("SMS Ethiopia response:", response.data);

    return response.data;
  } catch (error) {
    console.error("SMS Ethiopia error:", error.response?.data || error.message);

    throw error;
  }
}
