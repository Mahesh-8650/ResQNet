import express from "express";
import Hospital from "../models/Hospital.js";

const router = express.Router();

/* ===================================================== */
/* 🏥 GET NEAREST HOSPITALS */
/* ===================================================== */

router.get("/nearest", async (req, res) => {
  try {

    const { latitude, longitude } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        message: "Latitude and longitude required"
      });
    }

    const hospitals = await Hospital.find({
      status: "approved",
      location: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [
              Number(longitude),
              Number(latitude)
            ]
          }
        }
      }
    }).select("_id hospitalName location");

    return res.status(200).json({
      hospitals
    });

  } catch (error) {

    console.error("Fetch hospitals error:", error);

    return res.status(500).json({
      message: "Server error"
    });

  }
});

export default router;