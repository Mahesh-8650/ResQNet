import dotenv from "dotenv";
dotenv.config();

import express from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import twilio from "twilio";

import User from "../models/User.js";
import Hospital from "../models/Hospital.js";
import Ambulance from "../models/Ambulance.js";
import Otp from "../models/Otp.js";
import upload from "../middleware/upload.js";
import Admin from "../models/Admin.js";
import EmergencyRequest from "../models/EmergencyRequest.js";
import mongoose from "mongoose";

const router = express.Router();

const twilioClient = twilio(
  process.env.TWILIO_SID,
  process.env.TWILIO_AUTH_TOKEN
);

const passwordRegex =
  /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$/;

/* ===================================================== */
/* ================= USER REGISTRATION ================= */
/* ===================================================== */

router.post("/register/user", async (req, res) => {
  try {
    const {
      fullName,
      phone,
      email,
      password,
      dateOfBirth,
      bloodGroup,
      emergencyContact,
    } = req.body;

    if (
      !fullName ||
      !phone ||
      !email ||
      !password ||
      !dateOfBirth ||
      !bloodGroup ||
      !emergencyContact
    ) {
      return res.status(400).json({ message: "All fields required" });
    }

    if (!passwordRegex.test(password)) {
      return res.status(400).json({
        message:
          "Password must contain uppercase, lowercase, number and special character.",
      });
    }

    const existingPhone =
      (await User.findOne({ phone })) ||
      (await Hospital.findOne({ phone })) ||
      (await Ambulance.findOne({ phone }));

    if (existingPhone) {
      return res.status(400).json({
        message: "Phone number already registered with another account.",
      });
    }

    const existingEmail =
      (await User.findOne({ email })) ||
      (await Hospital.findOne({ email })) ||
      (await Ambulance.findOne({ email }));

    if (existingEmail) {
      return res.status(400).json({
        message: "Email already registered with another account.",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const hashedOtp = await bcrypt.hash(otp, 10);

    await Otp.deleteMany({ phone });

    await Otp.create({
      phone,
      otp: hashedOtp,
      expiresAt: new Date(Date.now() + 2 * 60 * 1000),
      registrationData: {
        type: "citizen",
        fullName,
        email,
        password: hashedPassword,
        dateOfBirth,
        bloodGroup,
        emergencyContact,
      },
    });

    await twilioClient.messages.create({
      body: `Your ResQNet verification OTP is ${otp}`,
      from: process.env.TWILIO_PHONE,
      to: phone,
    });

    return res.status(200).json({
      message: "OTP sent for verification.",
    });

  } catch (error) {
    console.error("USER REGISTER ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ================= HOSPITAL REGISTRATION ============= */
/* ===================================================== */

router.post(
  "/register/hospital",
  upload.single("certificate"),
  async (req, res) => {
    try {
      const {
        hospitalName,
        registrationNumber,
        email,
        password,
        phone,
        address,
        latitude,
        longitude,
      } = req.body;

      if (
        !hospitalName ||
        !registrationNumber ||
        !email ||
        !password ||
        !phone ||
        !address ||
        !latitude ||
        !longitude
      ) {
        return res.status(400).json({ message: "All fields required" });
      }

      if (!passwordRegex.test(password)) {
        return res.status(400).json({
          message:
            "Password must contain uppercase, lowercase, number and special character.",
        });
      }

      if (!req.file) {
        return res.status(400).json({ message: "Certificate file required" });
      }

      const existingPhone =
        (await User.findOne({ phone })) ||
        (await Hospital.findOne({ phone })) ||
        (await Ambulance.findOne({ phone }));

      if (existingPhone) {
        return res.status(400).json({
          message: "Phone number already registered with another account.",
        });
      }

      const existingEmail =
        (await User.findOne({ email })) ||
        (await Hospital.findOne({ email })) ||
        (await Ambulance.findOne({ email }));

      if (existingEmail) {
        return res.status(400).json({
          message: "Email already registered with another account.",
        });
      }

      const hashedPassword = await bcrypt.hash(password, 10);
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const hashedOtp = await bcrypt.hash(otp, 10);

      await Otp.deleteMany({ phone });

      await Otp.create({
        phone,
        otp: hashedOtp,
        expiresAt: new Date(Date.now() + 2 * 60 * 1000),
        registrationData: {
          type: "hospital",
          hospitalName,
          registrationNumber,
          email,
          password: hashedPassword,
          address,
          latitude,
          longitude,
          certificateFilePath: req.file.filename,
        },
      });

      await twilioClient.messages.create({
        body: `Your ResQNet hospital verification OTP is ${otp}`,
        from: process.env.TWILIO_PHONE,
        to: phone,
      });

      return res.status(200).json({
        message: "OTP sent for verification.",
      });

    } catch (error) {
      console.error("HOSPITAL REGISTER ERROR:", error);
      return res.status(500).json({ message: "Server error" });
    }
  }
);

/* ===================================================== */
/* ================= AMBULANCE REGISTRATION ============ */
/* ===================================================== */

router.post(
  "/register/ambulance",
  upload.fields([
    { name: "license", maxCount: 1 },
    { name: "rc", maxCount: 1 },
    { name: "permit", maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const {
        fullName,
        email,
        password,
        phone,
        licenseNumber,
        vehicleNumber,
      } = req.body;

      if (
        !fullName ||
        !email ||
        !password ||
        !phone ||
        !licenseNumber ||
        !vehicleNumber
      ) {
        return res.status(400).json({ message: "All fields required" });
      }

      if (!passwordRegex.test(password)) {
        return res.status(400).json({
          message:
            "Password must contain uppercase, lowercase, number and special character.",
        });
      }

      if (
        !req.files ||
        !req.files.license ||
        !req.files.rc ||
        !req.files.permit
      ) {
        return res.status(400).json({
          message: "License, RC and Permit documents are required",
        });
      }

      const existingPhone =
        (await User.findOne({ phone })) ||
        (await Hospital.findOne({ phone })) ||
        (await Ambulance.findOne({ phone }));

      if (existingPhone) {
        return res.status(400).json({
          message: "Phone number already registered with another account.",
        });
      }

      const existingEmail =
        (await User.findOne({ email })) ||
        (await Hospital.findOne({ email })) ||
        (await Ambulance.findOne({ email }));

      if (existingEmail) {
        return res.status(400).json({
          message: "Email already registered with another account.",
        });
      }

      const hashedPassword = await bcrypt.hash(password, 10);
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const hashedOtp = await bcrypt.hash(otp, 10);

      await Otp.deleteMany({ phone });

      await Otp.create({
        phone,
        otp: hashedOtp,
        expiresAt: new Date(Date.now() + 2 * 60 * 1000),
        registrationData: {
          type: "ambulance",
          fullName,
          email,
          password: hashedPassword,
          licenseNumber,
          vehicleNumber,
          licenseFilePath: req.files.license[0].filename,
          rcFilePath: req.files.rc[0].filename,
          permitFilePath: req.files.permit[0].filename,
        },
      });

      await twilioClient.messages.create({
        body: `Your ResQNet ambulance verification OTP is ${otp}`,
        from: process.env.TWILIO_PHONE,
        to: phone,
      });

      return res.status(200).json({
        message: "OTP sent for ambulance verification.",
      });

    } catch (error) {
      console.error("AMBULANCE REGISTER ERROR:", error);
      return res.status(500).json({ message: "Server error" });
    }
  }
);

/* ===================================================== */
/* ================= LOGIN SEND OTP ==================== */
/* ===================================================== */

router.post("/send-otp", async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ message: "Phone required" });
    }

    const user =
      (await User.findOne({ phone })) ||
      (await Hospital.findOne({ phone })) ||
      (await Ambulance.findOne({ phone }));

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (
      (user.role === "hospital" || user.role === "ambulance") &&
      user.status !== "approved"
    ) {
      return res.status(403).json({
        message: `${user.role} account awaiting admin approval.`,
      });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const hashedOtp = await bcrypt.hash(otp, 10);

    await Otp.deleteMany({ phone });

    await Otp.create({
      phone,
      otp: hashedOtp,
      expiresAt: new Date(Date.now() + 2 * 60 * 1000),
    });

    await twilioClient.messages.create({
      body: `Your ResQNet login OTP is ${otp}`,
      from: process.env.TWILIO_PHONE,
      to: phone,
    });

    return res.status(200).json({
      message: "Login OTP sent successfully",
    });

  } catch (error) {
    console.error("LOGIN SEND OTP ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ================= VERIFY OTP ========================= */
/* ===================================================== */

router.post("/verify-otp", async (req, res) => {
  try {
    const { phone, otp, fcmToken } = req.body;

    const record = await Otp.findOne({ phone });

    if (!record) return res.status(400).json({ message: "OTP expired" });

    if (record.expiresAt < new Date()) {
      await Otp.deleteOne({ phone });
      return res.status(400).json({ message: "OTP expired" });
    }

    const isMatch = await bcrypt.compare(otp, record.otp);

    if (!isMatch)
      return res.status(400).json({ message: "Invalid OTP" });

    await Otp.deleteOne({ phone });

    let account =
      (await User.findOne({ phone })) ||
      (await Hospital.findOne({ phone })) ||
      (await Ambulance.findOne({ phone }));

    if (!account && record.registrationData?.type === "citizen") {
      account = await User.create({
        ...record.registrationData,
        phone,
        role: "citizen",
        status: "approved",
      });
    }

    if (!account && record.registrationData?.type === "hospital") {
      await Hospital.create({
        hospitalName: record.registrationData.hospitalName,
        registrationNumber:
          record.registrationData.registrationNumber,
        email: record.registrationData.email,
        password: record.registrationData.password,
        phone,
        address: record.registrationData.address,
        location: {
          type: "Point",
          coordinates: [
            Number(record.registrationData.longitude),
            Number(record.registrationData.latitude),
          ],
        },
        certificateFilePath:
          record.registrationData.certificateFilePath,
        status: "pending",
        role: "hospital",
      });

      return res.json({
        message: "Verified successfully. Awaiting admin approval.",
      });
    }

    if (!account && record.registrationData?.type === "ambulance") {
      await Ambulance.create({
        fullName: record.registrationData.fullName,
        email: record.registrationData.email,
        password: record.registrationData.password,
        phone,
        licenseNumber: record.registrationData.licenseNumber,
        vehicleNumber: record.registrationData.vehicleNumber,
        licenseFilePath: record.registrationData.licenseFilePath,
        rcFilePath: record.registrationData.rcFilePath,
        permitFilePath: record.registrationData.permitFilePath,
        status: "pending",
        role: "ambulance",
      });

      return res.json({
        message:
          "Ambulance verified successfully. Awaiting admin approval.",
      });
    }

    if (!account)
      return res.status(404).json({ message: "Account not found" });
    if(account.role === "ambulance" && fcmToken){
      await
      Ambulance.findByIdAndUpdate(account._id,{
        fcmToken: fcmToken,
      });
    }

    const token = jwt.sign(
      { id: account._id, role: account.role },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.json({
      message: "Verification successful",
      token,
      account,
    });

  } catch (error) {
    console.error("VERIFY OTP ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

router.get("/admin/test-login", async (req, res) => {
  try {
    const admin = await Admin.findOne({ email: "admin@resqnet.com" });

    if (!admin) {
      return res.json({ message: "Admin not found" });
    }

    return res.json({
      message: "Admin exists",
      email: admin.email,
      role: admin.role
    });

  } catch (error) {
    return res.status(500).json({ message: "Error" });
  }
});

/* ===================================================== */
/* ================= ADMIN LOGIN ======================= */
/* ===================================================== */

router.post("/admin/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password required" });
    }

    const admin = await Admin.findOne({ email });

    if (!admin) {
      return res.status(404).json({ message: "Admin not found" });
    }

    const isMatch = await bcrypt.compare(password, admin.password);

    if (!isMatch) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const token = jwt.sign(
      { id: admin._id, role: admin.role },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.json({
      message: "Admin login successful",
      token,
      admin: {
        id: admin._id,
        email: admin.email,
        role: admin.role,
      },
    });

  } catch (error) {
    console.error("ADMIN LOGIN ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ============ UPDATE HOSPITAL RESOURCES ============== */
/* ===================================================== */

router.put("/hospital/update-resources", async (req, res) => {
  try {
    const {
      hospitalId,
      icuBedsAvailable,
      generalBedsAvailable,
      oxygenAvailable,
      emergencyAvailable,
    } = req.body;

    if (!hospitalId) {
      return res.status(400).json({ message: "Hospital ID required" });
    }

    const hospital = await Hospital.findById(hospitalId);

    if (!hospital) {
      return res.status(404).json({ message: "Hospital not found" });
    }

    hospital.icuBedsAvailable = icuBedsAvailable ?? hospital.icuBedsAvailable;
    hospital.generalBedsAvailable =
      generalBedsAvailable ?? hospital.generalBedsAvailable;
    hospital.oxygenAvailable =
      oxygenAvailable ?? hospital.oxygenAvailable;
    hospital.emergencyAvailable =
      emergencyAvailable ?? hospital.emergencyAvailable;

    hospital.lastUpdated = new Date();

    await hospital.save();

    return res.json({
      message: "Resources updated successfully",
      hospital,
    });

  } catch (error) {
    console.error("UPDATE HOSPITAL RESOURCES ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ============ GET HOSPITAL DETAILS =================== */
/* ===================================================== */

router.get("/hospital/:id", async (req, res) => {
  try {
    const hospital = await Hospital.findById(req.params.id);

    if (!hospital) {
      return res.status(404).json({ message: "Hospital not found" });
    }

    return res.json(hospital);

  } catch (error) {
    console.error("GET HOSPITAL ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ========== GET HOSPITAL INCOMING REQUESTS ========== */
/* ===================================================== */

router.get("/hospital/:id/requests", async (req, res) => {
  try {
    const hospitalId = new mongoose.Types.ObjectId(req.params.id);

    // 1️⃣ Get hospital details
    const hospital = await Hospital.findById(hospitalId);

    if (!hospital) {
      return res.status(404).json({ message: "Hospital not found" });
    }

    const hospitalCoords = hospital.location?.coordinates;

    // 2️⃣ Get pending requests
    const requests = await EmergencyRequest.find({
      hospitalId: hospitalId,
      status: "pending",
    })
      .populate(
        "ambulanceId",
        "fullName phone vehicleNumber currentLocation"
      )
      .sort({ createdAt: -1 });

    // 3️⃣ Haversine distance function
    const calculateDistance = (lat1, lon1, lat2, lon2) => {
      const R = 6371; // Earth radius in km
      const toRad = (value) => (value * Math.PI) / 180;

      const dLat = toRad(lat2 - lat1);
      const dLon = toRad(lon2 - lon1);

      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) *
          Math.cos(toRad(lat2)) *
          Math.sin(dLon / 2) *
          Math.sin(dLon / 2);

      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

      return R * c; // distance in km
    };

    const averageSpeed = 40; // km/h

    // 4️⃣ Add distance + ETA dynamically
    const enhancedRequests = requests.map((reqItem) => {
      let distanceKm = 0;
      let etaMinutes = null;

      const ambulanceCoords =
        reqItem.ambulanceId?.currentLocation?.coordinates;

      if (
        ambulanceCoords &&
        hospitalCoords &&
        ambulanceCoords.length === 2 &&
        hospitalCoords.length === 2
      ) {
        const [ambLng, ambLat] = ambulanceCoords;
        const [hosLng, hosLat] = hospitalCoords;

        // 🚨 Skip calculation if ambulance location is default [0,0]
        if (
          ambLat !== 0 &&
          ambLng !== 0 &&
          hosLat !== 0 &&
          hosLng !== 0
        ) {
          distanceKm = calculateDistance(
            ambLat,
            ambLng,
            hosLat,
            hosLng
          );

          etaMinutes = Math.max(
            1,
            Math.round((distanceKm / averageSpeed) * 60)
          );
        }
      }

      return {
        ...reqItem._doc,
        distanceKm: Number(distanceKm.toFixed(2)),
        etaMinutes,
      };
    });

    return res.json(enhancedRequests);

  } catch (error) {
    console.error("GET REQUESTS ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ===================================================== */
/* ========== MARK REQUEST AS COMPLETED =============== */
/* ===================================================== */

router.put("/hospital/request/:id/complete", async (req, res) => {
  try {
    const requestId = req.params.id;

    const request = await EmergencyRequest.findById(requestId);

    if (!request) {
      return res.status(404).json({ message: "Request not found" });
    }

    request.status = "completed";
    await request.save();

    return res.json({ message: "Marked as completed" });

  } catch (error) {
    console.error("COMPLETE REQUEST ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});
/* ===================================================== */
/* ========== GET COMPLETED REQUESTS =================== */
/* ===================================================== */

router.get("/hospital/:id/completed", async (req, res) => {
  try {
    const hospitalId = new mongoose.Types.ObjectId(req.params.id);

    const completedRequests = await EmergencyRequest.find({
      hospitalId: hospitalId,
      status: "completed",
    })
      .populate("ambulanceId", "fullName vehicleNumber phone")
      .sort({ updatedAt: -1 });

    return res.json(completedRequests);

  } catch (error) {
    console.error("GET COMPLETED ERROR:", error);
    return res.status(500).json({ message: "Server error" });
  }
});
export default router;