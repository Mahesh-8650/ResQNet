import express from "express";
import CitizenEmergency from "../models/CitizenEmergency.js";

const router = express.Router();

/* ===================================================== */
/* 🚑 AMBULANCE PERFORMANCE STATS */
/* ===================================================== */

router.get("/:ambulanceId", async (req, res) => {
  try {
    const { ambulanceId } = req.params;

    // ✅ Total Completed Cases
    const totalCompleted = await CitizenEmergency.countDocuments({
      ambulanceId,
      status: "completed",
    });

    // ✅ This Month Completed Cases
    const now = new Date();
    const firstDayOfMonth = new Date(
      now.getFullYear(),
      now.getMonth(),
      1
    );

    const monthlyCompleted = await CitizenEmergency.countDocuments({
      ambulanceId,
      status: "completed",
      completedAt: { $gte: firstDayOfMonth },
    });

    // ✅ Fetch all completed cases for calculations
    const completedCases = await CitizenEmergency.find({
      ambulanceId,
      status: "completed",
    });

    // ✅ Average Response Time
    let avgResponseTime = 0;

    if (completedCases.length > 0) {
      const totalResponseTime = completedCases.reduce(
        (sum, c) => sum + (c.responseTimeInSeconds || 0),
        0
      );

      avgResponseTime =
        totalResponseTime / completedCases.length;
    }

    // ✅ Acceptance Rate
    const totalOffered = await CitizenEmergency.countDocuments({
      ambulanceId,
      offeredAt: { $ne: null },
    });

    const totalAccepted = await CitizenEmergency.countDocuments({
      ambulanceId,
      status: { $in: ["assigned", "completed"] },
    });

    let acceptanceRate = 0;

    if (totalOffered > 0) {
      acceptanceRate =
        (totalAccepted / totalOffered) * 100;
    }

    // ✅ Total Distance Covered
    const totalDistance = completedCases.reduce(
      (sum, c) => sum + (c.distanceCoveredKm || 0),
      0
    );

    return res.status(200).json({
      totalCompleted,
      monthlyCompleted,
      avgResponseTime: Number(avgResponseTime.toFixed(2)),
      acceptanceRate: Number(acceptanceRate.toFixed(2)),
      totalDistance: Number(totalDistance.toFixed(2)),
    });

  } catch (error) {
    console.error("Performance fetch error:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

export default router;