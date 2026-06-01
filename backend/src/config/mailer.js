import { BrevoClient } from "@getbrevo/brevo";
import { logger } from "./logger.js";

let client = null;
let senderEmail = null;
let senderName = null;

export async function initMailer() {
  try {
    // =========================
    // 1. TEST MODE
    // =========================
    if (process.env.NODE_ENV === "test") {
      client = {
        transactionalEmails: {
          sendTransacEmail: async (msg) => {
            globalThis.__lastMail = msg;
            return { messageId: "test-" + Date.now() };
          },
        },
      };
      logger.info("Mailer running in TEST mode");
      return;
    }

    // =========================
    // 2. BREVO HTTP API
    // =========================
    if (!process.env.BREVO_API_KEY) throw new Error("BREVO_API_KEY is not set");

    senderEmail = process.env.MAIL_FROM || process.env.BREVO_SENDER_EMAIL;
    senderName = process.env.BREVO_SENDER_NAME || "School Recommendation";

    if (!senderEmail) throw new Error("MAIL_FROM or BREVO_SENDER_EMAIL is not set");

    client = new BrevoClient({ apiKey: process.env.BREVO_API_KEY });

    // Verify credentials
    await client.account.getAccount();

    logger.info("Brevo client initialized successfully");
  } catch (err) {
    logger.error({ err }, "Failed to initialize mailer");
    throw err;
  }
}

export async function sendMail({ to, subject, text, html }) {
  if (!client) {
    throw new Error("Mailer not initialized. Call initMailer() first.");
  }

  try {
    const result = await client.transactionalEmails.sendTransacEmail({
      sender: { email: senderEmail, name: senderName },
      to: [{ email: to }],
      subject,
      textContent: text,
      ...(html && { htmlContent: html }),
    });

    logger.info({ to, subject, messageId: result.messageId }, "Email sent successfully");
    return result;
  } catch (err) {
    logger.error({ err, to }, "Email sending failed");
    throw err;
  }
}