import "dotenv/config";
import { BrevoClient } from "@getbrevo/brevo";

const TEST_TO = "youseftela@gmail.com";

async function main() {
  if (!process.env.BREVO_API_KEY) {
    console.error("❌ BREVO_API_KEY is not set in .env");
    process.exit(1);
  }

  if (!process.env.MAIL_FROM) {
    console.error("❌ MAIL_FROM is not set in .env");
    process.exit(1);
  }

  console.log("🔧 Initializing Brevo client...");
  const client = new BrevoClient({ apiKey: process.env.BREVO_API_KEY });

  console.log("📤 Sending test email to", TEST_TO);
  const result = await client.transactionalEmails.sendTransacEmail({
    sender: { email: process.env.MAIL_FROM, name: process.env.BREVO_SENDER_NAME || "Test" },
    to: [{ email: TEST_TO }],
    subject: "Test email from School Recommendation",
    textContent: "If you're reading this, Brevo email sending is working correctly.",
  });

  console.log("✅ Email sent! Message ID:", result.messageId);
}

main().catch((err) => {
  console.error("❌ Failed:", err.message);
  process.exit(1);
});