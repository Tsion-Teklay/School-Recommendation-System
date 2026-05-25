import { sendMail } from "../config/mailer.js";
import { logger } from "../config/logger.js";

function frontendBaseUrl() {
  return (
    process.env.FRONTEND_URL ||
    process.env.APP_URL?.replace(":5050", ":3000") ||
    "http://localhost:3000"
  );
}

/**
 * Sent when a moderator approves the ad content — includes amount and pay link.
 */
export async function sendAdPaymentInstructionsEmail({
  to,
  adId,
  paymentId,
  title,
  amountEtb,
  durationDays,
  placementType,
}) {
  const payUrl = `${frontendBaseUrl()}/advertise/pay/${adId}`;
  const subject = `Your advertisement was approved — payment required`;
  const text = [
    `Your advertisement "${title}" has been approved.`,
    ``,
    `Amount due: ${amountEtb} ETB`,
    `Duration: ${durationDays} days`,
    `Placement: ${placementType}`,
    `Payment record ID: ${paymentId || "(not available)"}`,
    ``,
    `Complete payment here: ${payUrl}`,
    ``,
    `Supported methods: Telebirr, CBE Birr, or bank transfer.`,
    `After payment is submitted, your ad will go live for the selected period.`,
    ``,
    `Important: When you make the payment, you will receive a payment reference (transaction id) from your payment provider. Enter that transaction id on the payment page and submit it — the payment will be matched using that reference. Please also use the same email address you used when creating the ad request.`,
  ].join("\n");

  const html = `
    <p>Your advertisement <strong>${title}</strong> has been approved.</p>
    <ul>
      <li><strong>Amount due:</strong> ${amountEtb} ETB</li>
      <li><strong>Duration:</strong> ${durationDays} days</li>
      <li><strong>Placement:</strong> ${placementType}</li>
      <li><strong>Payment record ID:</strong> ${paymentId || "(not available)"}</li>
    </ul>
    <p><a href="${payUrl}">Complete payment on our platform</a></p>
    <p>Telebirr, CBE Birr, and bank transfer are accepted. Your ad goes live after payment is recorded.</p>
    <p><strong>Note:</strong> After you pay you'll receive a payment reference (transaction id) from your payment provider — please enter that reference on the payment page and submit it along with your email so we can match the payment.</p>
  `;

  try {
    await sendMail({ to, subject, text, html });
  } catch (err) {
    logger.error({ err, adId, to }, "Failed to send ad payment email");
    throw err;
  }
}
