import dotenv from "dotenv";
dotenv.config(); // MUST be first

import express from "express";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";

import connectDB from "./config/db.js";
import authRoutes from "./routes/authRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";

const app = express();

/* ===================================================== */
/* ================= MIDDLEWARE ======================== */
/* ===================================================== */

app.use(cors());
app.use(express.json());

/* ===================================================== */
/* ================= STATIC FILES ====================== */
/* ===================================================== */

// Fix for ES module (__dirname not available directly)
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 🔥 Serve uploads folder
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

/* ===================================================== */
/* ================= DATABASE ========================== */
/* ===================================================== */

connectDB();

/* ===================================================== */
/* ================= ROUTES ============================ */
/* ===================================================== */

app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);

/* ===================================================== */
/* ================= TEST ROUTE ======================== */
/* ===================================================== */

app.get("/", (req, res) => {
  res.send("ResQNet backend running");
});

/* ===================================================== */
/* ================= SERVER START ====================== */
/* ===================================================== */

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});