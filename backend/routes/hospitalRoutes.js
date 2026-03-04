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

    const hospitals = await Hospital.aggregate([
  {
    $geoNear: {
      near: {
        type: "Point",
        coordinates: [
          Number(longitude),
          Number(latitude)
        ]
      },
      distanceField: "distance",
      spherical: true,
      query: { status: "approved" }
    }
  },
  {
    $project: {
      _id: 1,
      hospitalName: 1,
      address: 1,
      distance: {
        $divide: ["$distance", 1000] // convert meters to KM
      }
    }
  }
]);

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