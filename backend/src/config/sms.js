import axios from "axios";

export async function sendSMS({ to, message }) {
  try {
    const response = await axios.post(
      "https://api.afromessage.com/api/send",
      {
        from: process.env.AFROMESSAGE_SENDER,
        to,
        message,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.AFROMESSAGE_API_KEY}`,
          "Content-Type": "application/json",
        },
      },
    );

    console.log("SMS sent:", response.data);

    return response.data;
  } catch (error) {
    console.error("SMS STATUS:", error.response?.status);

    console.error(
      "SMS RESPONSE DATA:",
      JSON.stringify(error.response?.data, null, 2),
    );

    console.error("SMS RESPONSE HEADERS:", error.response?.headers);

    console.error("SMS ERROR:", error.message);

    throw new Error("Failed to send SMS");
  }
}
