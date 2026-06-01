import nodemailer from "nodemailer";
import { logger } from "./logger.js";

let transporter = null;

/**
 * Initialize mailer once at app startup
 */
export async function initMailer() {
  try {
    // =========================
    // 1. TEST MODE (NO SMTP)
    // =========================
    if (process.env.NODE_ENV === "test") {
      transporter = {
        sendMail: async (msg) => {
          globalThis.__lastMail = msg;
          return { messageId: "test-" + Date.now() };
        },
      };

      logger.info("Mailer running in TEST mode");
      return;
    }

    // =========================
    // 2. DEV / PROD SMTP MODE
    // =========================
    transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT),
      secure: Number(process.env.SMTP_PORT) === 465,

      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },

      connectionTimeout: 30000,
      greetingTimeout: 30000,
      socketTimeout: 30000,
    });

    await transporter.verify();

    logger.info("SMTP transporter initialized successfully");
  } catch (err) {
    logger.error({ err }, "Failed to initialize mailer");
    throw err;
  }
}

/**
 * Get transporter
 */
export function getTransporter() {
  if (!transporter) {
    throw new Error("Mailer not initialized. Call initMailer() first.");
  }
  return transporter;
}

/**
 * Send email safely
 */
export async function sendMail({ to, subject, text, html }) {
  try {
    const t = getTransporter();

    const info = await t.sendMail({
      from: process.env.MAIL_FROM || "no-reply@schoolrec.local",
      to,
      subject,
      text,
      html,
    });

    logger.info(
      { to, subject, messageId: info.messageId },
      "Email sent successfully"
    );

    return info;
  } catch (err) {
    logger.error({ err, to }, "Email sending failed");
    throw err;
  }
}