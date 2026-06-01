import nodemailer from "nodemailer";
import dotenv from "dotenv";
dotenv.config();

async function testSMTP() {
  console.log("🚀 Starting SMTP test...");

  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || "smtp-relay.brevo.com",
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_PORT == "465",

    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },

    connectionTimeout: 30000,
    greetingTimeout: 30000,
    socketTimeout: 30000,
  });

  try {
    console.log("🔍 Verifying connection...");
    await transporter.verify();
    console.log("✅ SMTP connection successful!");

    console.log("📧 Sending test email...");

    const result = await transporter.sendMail({
      from: `"SMTP Test" <${process.env.SMTP_USER}>`,
      to: process.env.TEST_EMAIL || process.env.SMTP_USER,
      subject: "SMTP Test Email",
      text: "If you received this, SMTP is working 🎉",
    });

    console.log("✅ Email sent successfully!");
    console.log("Message ID:", result.messageId);
  } catch (err) {
    console.error("❌ SMTP TEST FAILED");
    console.error("Error message:", err.message);
    console.error("Full error:", err);
  }
}

testSMTP();