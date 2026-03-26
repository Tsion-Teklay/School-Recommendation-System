import express from "express";
import cors from "cors";

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("API running");
});

app.use("/api/auth", (await import("./routes/auth.routes.js")).default);

app.use("/api/schools", (await import("./routes/school.routes.js")).default);

app.use("/api/test", (await import("./routes/test.routes.js")).default);

app.use("/api/recommendations", (await import("./routes/recommendation.routes.js")).default);

app.use("/api/preferences/", (await import("./routes/preference.routes.js")).default);

app.use("/api/favorites/", (await import("./routes/favorite.routes.js")).default);

app.use("/api/reviews/", (await import("./routes/review.routes.js")).default);

app.use("/api/announcements/", (await import("./routes/announcement.routes.js")).default);

app.use("/api/reports/", (await import("./routes/report.routes.js")).default);

app.use("/api/notifications/", (await import("./routes/notification.routes.js")).default);

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Something went wrong!" });
});

export default app;