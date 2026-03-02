import dotenv from "dotenv";
dotenv.config(); // MUST be first

import express from "express";
import cors from "cors";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

import connectDB from "./config/db.js";
import authRoutes from "./routes/authRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";
import citizenEmergencyRoutes from "./routes/citizenEmergencyRoutes.js";

/* ===================================================== */
/* ================= EXPRESS APP ======================= */
/* ===================================================== */

const app = express();

/* ===================================================== */
/* ================= FIX FOR __dirname ================= */
/* ===================================================== */

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/* ===================================================== */
/* ================= CREATE UPLOADS FOLDER ============= */
/* ===================================================== */

// 🔥 IMPORTANT FOR RENDER
const uploadDir = path.join(__dirname, "uploads");

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
  console.log("Uploads folder created");
}

/* ===================================================== */
/* ================= MIDDLEWARE ======================== */
/* ===================================================== */

app.use(cors());
app.use(express.json());

/* ===================================================== */
/* ================= STATIC FILES ====================== */
/* ===================================================== */

app.use("/uploads", express.static(uploadDir));

/* ===================================================== */
/* ================= DATABASE ========================== */
/* ===================================================== */

connectDB();

/* ===================================================== */
/* ================= ROUTES ============================ */
/* ===================================================== */

app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/citizen-emergency", citizenEmergencyRoutes);

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