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
      hospitalId,
    } = req.body;

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
/* 🚑 GET ACTIVE EMERGENCY FOR AMBULANCE */
/* ===================================================== */

router.get("/ambulance/:ambulanceId", async (req, res) => {
  try {
    const { ambulanceId } = req.params;

    const emergency = await CitizenEmergency.findOne({
      ambulanceId,
      status: { $in: ["assigned", "pickup", "enroute", "at_hospital"] },
    }).sort({ createdAt: -1 });

    if (!emergency) {
      return res.status(200).json({
        hasEmergency: false,
      });
    }

    return res.status(200).json({
      hasEmergency: true,
      emergency,
    });

  } catch (error) {
    console.error("Fetch ambulance emergency error:", error);
    return res.status(500).json({
      message: "Server error",
    });
  }
});

/* ===================================================== */

export default router;