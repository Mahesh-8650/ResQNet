import express from "express";
import CitizenEmergency from "../models/CitizenEmergency.js";

const router = express.Router();

/* ===================================================== */
/* 🚑 CREATE CITIZEN EMERGENCY */
/* ===================================================== */

router.post("/create", async (req, res) => {
  try {
    const {
      patientName,
      emergencyType,
      latitude,
      longitude,
      hospitalId, // optional
    } = req.body;

    // Basic validation
    if (!patientName || !emergencyType || !latitude || !longitude) {
      return res.status(400).json({
        message: "Missing required fields",
      });
    }

    const emergency = new CitizenEmergency({
      patientName,
      emergencyType,
      patientLocation: {
        latitude,
        longitude,
      },
      hospitalId: hospitalId || null,
      selectedBy: hospitalId ? "user" : null,
      status: "pending",
    });

    await emergency.save();

    res.status(201).json({
      message: "Emergency created successfully",
      emergency,
    });

  } catch (error) {
    console.error("Create emergency error:", error);
    res.status(500).json({
      message: "Server error",
    });
  }
});

/* ===================================================== */

export default router;