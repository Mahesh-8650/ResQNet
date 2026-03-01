import express from "express";
import CitizenEmergency from "../models/CitizenEmergency.js";
import Ambulance from "../models/Ambulance.js";
import Hospital from "../models/Hospital.js";

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

    let assignedHospitalId = hospitalId || null;

    /* ================= AUTO ASSIGN HOSPITAL ================= */

    if (!hospitalId) {
      const hospitals = await Hospital.find();

      if (hospitals.length > 0) {
        assignedHospitalId = hospitals[0]._id; // simple nearest logic placeholder
      }
    }

    const emergency = new CitizenEmergency({
      patientName,
      emergencyType,
      patientLocation: {
        latitude,
        longitude,
      },
      hospitalId: assignedHospitalId,
      selectedBy: hospitalId ? "user" : "system",
      status: "pending",
    });

    await emergency.save();

    return res.status(201).json({
      message: "Emergency created successfully",
      emergency,
    });

  } catch (error) {
    console.error("Create emergency error:", error);
    return res.status(500).json({
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
      status: "assigned",
    })
      .populate("hospitalId")
      .sort({ createdAt: -1 });

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
/* 🚑 UPDATE EMERGENCY STATUS */
/* ===================================================== */

router.put("/update-status/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const allowedStatuses = ["assigned", "completed"];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        message: "Invalid status value",
      });
    }

    const emergency = await CitizenEmergency.findById(id);

    if (!emergency) {
      return res.status(404).json({
        message: "Emergency not found",
      });
    }

    emergency.status = status;

    if (status === "completed") {
      await Ambulance.findByIdAndUpdate(
        emergency.ambulanceId,
        { isBusy: false }
      );

      emergency.ambulanceId = null;
    }

    await emergency.save();

    return res.status(200).json({
      message: "Status updated successfully",
      emergency,
    });

  } catch (error) {
    console.error("Update status error:", error);
    return res.status(500).json({
      message: "Server error",
    });
  }
});

/* ===================================================== */

export default router;