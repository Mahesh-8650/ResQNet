import express from "express";
import CitizenEmergency from "../models/CitizenEmergency.js";
import Ambulance from "../models/Ambulance.js";
import Hospital from "../models/Hospital.js";
import admin from "../config/firebaseAdmin.js";

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

    if (!hospitalId) {
      const hospitals = await Hospital.find();
      if (hospitals.length > 0) {
        assignedHospitalId = hospitals[0]._id;
      }
    }

    const emergency = await CitizenEmergency.create({
      patientName,
      emergencyType,
      patientLocation: { latitude, longitude },
      hospitalId: assignedHospitalId,
      selectedBy: hospitalId ? "user" : "system",
      status: "pending",
    });

    await offerToNextAmbulance(emergency._id);

    return res.status(201).json({
      message: "Emergency created successfully",
      emergency,
    });

  } catch (error) {
    console.error("Create emergency error:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* 🚑 OFFER LOGIC FUNCTION */
/* ===================================================== */

async function offerToNextAmbulance(emergencyId) {

  const emergency = await CitizenEmergency.findById(emergencyId);

  if (!emergency || emergency.status === "assigned") return;

  const availableAmbulance = await Ambulance.findOne({
    isAvailable: true,
    isBusy: false,
  });

  if (!availableAmbulance) return;

  emergency.ambulanceId = availableAmbulance._id;
  emergency.status = "offered";
  await emergency.save();

  /* ===== 🔔 SEND PUSH NOTIFICATION ===== */

  if (availableAmbulance.fcmToken) {
    try {
      await admin.messaging().send({
        token: availableAmbulance.fcmToken,
        notification: {
          title: "🚑 New Emergency Request",
          body: `Patient: ${emergency.patientName} | ${emergency.emergencyType}`,
        },
        data: {
          emergencyId: emergency._id.toString(),
          type: "emergency_offer",
        },
      });
    } catch (err) {
      console.error("FCM Send Error:", err);
    }
  }

  /* ===== 60 SECOND TIMEOUT ===== */

  setTimeout(async () => {

    const updatedEmergency = await CitizenEmergency.findById(emergencyId);
    if (!updatedEmergency) return;

    if (updatedEmergency.status === "offered") {
      updatedEmergency.ambulanceId = null;
      updatedEmergency.status = "pending";
      await updatedEmergency.save();

      await offerToNextAmbulance(emergencyId);
    }

  }, 60000);
}

/* ===================================================== */
/* 🚑 GET ACTIVE EMERGENCY FOR AMBULANCE */
/* ===================================================== */

router.get("/ambulance/:ambulanceId", async (req, res) => {
  try {
    const { ambulanceId } = req.params;

    const emergency = await CitizenEmergency.findOne({
      ambulanceId,
      status: { $in: ["offered", "assigned"] },
    })
      .populate(
        "hospitalId",
        "hospitalName address phone location"
      )
      .sort({ createdAt: -1 });

    if (!emergency) {
      return res.status(200).json({ hasEmergency: false });
    }

    return res.status(200).json({
      hasEmergency: true,
      emergency,
    });

  } catch (error) {
    console.error("Fetch ambulance emergency error:", error);
    return res.status(500).json({ message: "Server error" });
  }
});
/* ===================================================== */
/* 🚑 DRIVER ACCEPT EMERGENCY */
/* ===================================================== */

router.put("/respond/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { ambulanceId } = req.body;

    if (!ambulanceId) {
      return res.status(400).json({
        message: "Ambulance ID is required",
      });
    }

    const emergency = await CitizenEmergency.findById(id);

    if (!emergency) {
      return res.status(404).json({
        message: "Emergency not found",
      });
    }

    if (emergency.status !== "offered") {
      return res.status(400).json({
        message: "Emergency no longer available",
      });
    }

    // ✅ Update emergency
    emergency.status = "assigned";
    await emergency.save();

    // ✅ Update ambulance
    const updatedAmbulance = await Ambulance.findByIdAndUpdate(
      ambulanceId,
      {
        isBusy: true,
        isAvailable: false,
      },
      { new: true }
    );

    console.log("Updated Ambulance:", updatedAmbulance);

    return res.status(200).json({
      message: "Emergency accepted",
      emergency,
      ambulance: updatedAmbulance,
    });

  } catch (error) {
    console.error("Accept emergency error:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* 🚑 COMPLETE EMERGENCY */
/* ===================================================== */

router.put("/update-status/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (status !== "completed") {
      return res.status(400).json({
        message: "Only completed status allowed",
      });
    }

    const emergency = await CitizenEmergency.findById(id);

    if (!emergency) {
      return res.status(404).json({
        message: "Emergency not found",
      });
    }

    emergency.status = "completed";

    if (emergency.ambulanceId) {
      await Ambulance.findByIdAndUpdate(
        emergency.ambulanceId,
        { isBusy: false }
      );
    }

    emergency.ambulanceId = null;
    await emergency.save();

    return res.status(200).json({
      message: "Emergency completed",
      emergency,
    });

  } catch (error) {
    console.error("Complete emergency error:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

export default router;