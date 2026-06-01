import "dotenv/config";
import app from "./src/app.js";
import cron from "node-cron";  
import { enforceDeactivationLimit } from "./src/services/user.service.js";
import { initMailer } from "./src/config/mailer.js";

const PORT = process.env.PORT || 5000;

async function start() {
  try {
    await initMailer();
    console.log("Mailer initialized");
  } catch (err) {
    console.error("Failed to initialize mailer:", err);
  }

  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });

  // Run daily at midnight  
  cron.schedule("0 0 * * *", async () => {  
    try {  
      await enforceDeactivationLimit();  
      logger.info("Deactivation limit enforcement completed");  
    } catch (err) {  
      logger.error({ err }, "Failed to enforce deactivation limit");  
    }  
  });
}

start();
