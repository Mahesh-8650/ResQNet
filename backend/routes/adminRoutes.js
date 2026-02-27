import express from "express";
import Hospital from "../models/Hospital.js";
import Ambulance from "../models/Ambulance.js";

const router = express.Router();

/* ===================================================== */
/* ============ GET ALL PENDING HOSPITALS ============== */
/* ===================================================== */

router.get("/hospitals/pending", async (req, res) => {
  try {
    const hospitals = await Hospital.find({ status: "pending" });

    return res.json({
      count: hospitals.length,
      hospitals,
    });

  } catch (error) {
    console.error("GET PENDING HOSPITALS ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ================ APPROVE HOSPITAL =================== */
/* ===================================================== */

router.put("/hospitals/:id/approve", async (req, res) => {
  try {
    const { id } = req.params;

    const hospital = await Hospital.findByIdAndUpdate(
      id,
      { status: "approved" },
      { new: true }
    );

    if (!hospital) {
      return res.status(404).json({ message: "Hospital not found" });
    }

    return res.json({
      message: "Hospital approved successfully",
      hospital,
    });

  } catch (error) {
    console.error("APPROVE HOSPITAL ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ============== GET PENDING AMBULANCES =============== */
/* ===================================================== */

router.get("/ambulances/pending", async (req, res) => {
  try {
    const ambulances = await Ambulance.find({ status: "pending" });

    return res.json({
      count: ambulances.length,
      ambulances,
    });

  } catch (error) {
    console.error("GET PENDING AMBULANCES ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ============== APPROVE AMBULANCE ==================== */
/* ===================================================== */

router.put("/ambulances/:id/approve", async (req, res) => {
  try {
    const ambulance = await Ambulance.findById(req.params.id);

    if (!ambulance) {
      return res.status(404).json({ message: "Ambulance not found" });
    }

    ambulance.status = "approved";
    await ambulance.save();

    return res.json({
      message: "Ambulance approved successfully",
      ambulance,
    });

  } catch (error) {
    console.error("APPROVE AMBULANCE ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ================= REJECT HOSPITAL =================== */
/* ===================================================== */

router.put("/hospitals/:id/reject", async (req, res) => {
  try {
    const hospital = await Hospital.findById(req.params.id);

    if (!hospital) {
      return res.status(404).json({ message: "Hospital not found" });
    }

    hospital.status = "rejected";
    await hospital.save();

    return res.json({
      message: "Hospital rejected successfully",
      hospital,
    });

  } catch (error) {
    console.error("REJECT HOSPITAL ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* =============== REJECT AMBULANCE ==================== */
/* ===================================================== */

router.put("/ambulances/:id/reject", async (req, res) => {
  try {
    const ambulance = await Ambulance.findById(req.params.id);

    if (!ambulance) {
      return res.status(404).json({ message: "Ambulance not found" });
    }

    ambulance.status = "rejected";
    await ambulance.save();

    return res.json({
      message: "Ambulance rejected successfully",
      ambulance,
    });

  } catch (error) {
    console.error("REJECT AMBULANCE ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

router.get("/hospitals/approved", async (req, res) => {
  try {
    const hospitals = await Hospital.find({ status: "approved" });

    res.json({
      count: hospitals.length,
      hospitals
    });

  } catch (error) {
    console.error("GET APPROVED HOSPITALS ERROR:", error);
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/hospitals/rejected", async (req, res) => {
  try {
    const hospitals = await Hospital.find({ status: "rejected" });

    res.json({
      count: hospitals.length,
      hospitals
    });

  } catch (error) {
    console.error("GET REJECTED HOSPITALS ERROR:", error);
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/ambulances/approved", async (req, res) => {
  try {
    const ambulances = await Ambulance.find({ status: "approved" });

    res.json({
      count: ambulances.length,
      ambulances
    });

  } catch (error) {
    console.error("GET APPROVED AMBULANCES ERROR:", error);
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/ambulances/rejected", async (req, res) => {
  try {
    const ambulances = await Ambulance.find({ status: "rejected" });

    res.json({
      count: ambulances.length,
      ambulances
    });

  } catch (error) {
    console.error("GET REJECTED AMBULANCES ERROR:", error);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;