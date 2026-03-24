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

export default app;