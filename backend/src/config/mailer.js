import * as SibApiV3Sdk from "@getbrevo/brevo";
import { logger } from "./logger.js";

let brevoClient = null;
let senderEmail = null;
let senderName = null;

/**
 * Initialize mailer once at app startup
 */
export async function initMailer() {
  try {
    // =========================
    // 1. TEST MODE
    // =========================
    if (process.env.NODE_ENV === "test") {
      brevoClient = {
        sendTransacEmail: async (msg) => {
          globalThis.__lastMail = msg;
          return { messageId: "test-" + Date.now() };
        },
      };
      logger.info("Mailer running in TEST mode");
      return;
    }

    // =========================
    // 2. BREVO HTTP API
    // =========================
    if (!process.env.BREVO_API_KEY) {
      throw new Error("BREVO_API_KEY is not set");
    }

    const apiInstance = new SibApiV3Sdk.TransactionalEmailsApi();
    apiInstance.authentications["apiKey"].apiKey = process.env.BREVO_API_KEY;

    brevoClient = apiInstance;
    senderEmail = process.env.MAIL_FROM || process.env.BREVO_SENDER_EMAIL;
    senderName = process.env.BREVO_SENDER_NAME || "School Recommendation";

    if (!senderEmail) {
      throw new Error("MAIL_FROM or BREVO_SENDER_EMAIL is not set");
    }

    // Verify credentials with a lightweight API call
    const accountApi = new SibApiV3Sdk.AccountApi();
    accountApi.authentications["apiKey"].apiKey = process.env.BREVO_API_KEY;
    await accountApi.getAccount();

    logger.info("Brevo transactional email client initialized successfully");
  } catch (err) {
    logger.error({ err }, "Failed to initialize mailer");
    throw err;
  }
}

/**
 * Send email safely
 */
export async function sendMail({ to, subject, text, html }) {
  if (!brevoClient) {
    throw new Error("Mailer not initialized. Call initMailer() first.");
  }

  try {
    const sendSmtpEmail = new SibApiV3Sdk.SendSmtpEmail();

    sendSmtpEmail.sender = { email: senderEmail, name: senderName };
    sendSmtpEmail.to = [{ email: to }];
    sendSmtpEmail.subject = subject;
    sendSmtpEmail.textContent = text;
    if (html) sendSmtpEmail.htmlContent = html;

    const result = await brevoClient.sendTransacEmail(sendSmtpEmail);

    logger.info(
      { to, subject, messageId: result.messageId },
      "Email sent successfully"
    );

    return result;
  } catch (err) {
    logger.error({ err, to }, "Email sending failed");
    throw err;
  }
}