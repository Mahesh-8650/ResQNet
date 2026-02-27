import mongoose from "mongoose";

const hospitalSchema = new mongoose.Schema(
  {
    hospitalName: {
      type: String,
      required: true,
      trim: true,
    },

    registrationNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    password: {
      type: String,
      required: true,
    },

    phone: {
      type: String,
      required: true,
      unique: true,
    },

    // 🔥 Human readable address
    address: {
      type: String,
      required: true,
    },

    // 🔥 GeoJSON for maps & nearest search
    location: {
      type: {
        type: String,
        enum: ["Point"],
        required: true,
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },

    certificateFilePath: {
      type: String,
      required: true,
    },

    /* ===============================
       🔥 HOSPITAL RESOURCE FIELDS
    ================================ */

    icuBedsAvailable: {
      type: Number,
      default: 0,
    },

    generalBedsAvailable: {
      type: Number,
      default: 0,
    },

    oxygenAvailable: {
      type: Boolean,
      default: false,
    },

    emergencyAvailable: {
      type: Boolean,
      default: false,
    },

    lastUpdated: {
      type: Date,
      default: null,
    },

    /* =============================== */

    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },

    role: {
      type: String,
      default: "hospital",
    },
  },
  { timestamps: true }
);

// 🔥 Required for nearest hospital search
hospitalSchema.index({ location: "2dsphere" });

export default mongoose.model("Hospital", hospitalSchema);