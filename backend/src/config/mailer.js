import nodemailer from "nodemailer";
import { logger } from "./logger.js";

/**
 * Mail delivery.
 *
 * Local dev default: Nodemailer creates an **Ethereal** test inbox on first
 * use. Every sent email gets a preview URL you can open in the browser —
 * no real SMTP account required. Set `SMTP_URL` in `.env` to override with
 * Gmail / SendGrid / etc. when you deploy.
 *
 * In the test environment we skip SMTP entirely and stash the last message
 * on `globalThis.__lastMail` so tests can assert against it without a real
 * mail server.
 */

let transporterPromise = null;

function buildTransporter() {
  if (process.env.SMTP_URL) {
    return Promise.resolve(nodemailer.createTransport(process.env.SMTP_URL));
  }

  if (process.env.NODE_ENV === "test") {
    // In tests, no real network — capture messages instead.
    return Promise.resolve({
      sendMail: async (msg) => {
        globalThis.__lastMail = msg;
        return { messageId: "test-" + Date.now() };
      },
    });
  }

  // Dev default: Ethereal. One-shot account per process.
  return nodemailer.createTestAccount().then((account) => {
    logger.info(
      { user: account.user, web: "https://ethereal.email/login" },
      "Using Ethereal test SMTP — log in with these credentials to see sent mail"
    );
    return nodemailer.createTransport({
      host: account.smtp.host,
      port: account.smtp.port,
      secure: account.smtp.secure,
      auth: { user: account.user, pass: account.pass },
    });
  });
}

async function getTransporter() {
  if (!transporterPromise) transporterPromise = buildTransporter();
  return transporterPromise;
}

/**
 * Send an email. Safe to call in any environment — uses Ethereal/capture
 * when SMTP_URL is absent.
 */
export async function sendMail({ to, subject, text, html }) {
  const from = process.env.MAIL_FROM || "no-reply@schoolrec.local";
  const transporter = await getTransporter();
  const info = await transporter.sendMail({ from, to, subject, text, html });

  // Ethereal returns a preview URL we surface in the log for convenience.
  const preview = nodemailer.getTestMessageUrl?.(info);
  if (preview) {
    logger.info({ to, subject, preview }, "Email sent (Ethereal preview)");
  }
  return info;
}
