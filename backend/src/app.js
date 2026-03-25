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

export default app;