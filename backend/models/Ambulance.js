import mongoose from "mongoose";

const ambulanceSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
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

    vehicleNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    licenseNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    // 🔴 Live Location (GeoJSON)
    currentLocation: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: [0, 0],
      },
    },

    isAvailable: {
      type: Boolean,
      default: false,
    },

    isBusy: {
      type: Boolean,
      default: false,
    },

    rcFilePath: {
      type: String,
      required: true,
    },

    licenseFilePath: {
      type: String,
      required: true,
    },

    permitFilePath: {
      type: String,
      required: true,
    },

    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },

    role: {
      type: String,
      default: "ambulance",
    },
  },
  { timestamps: true }
);

// 🔥 Geo index for nearest ambulance search
ambulanceSchema.index({ currentLocation: "2dsphere" });

export default mongoose.model("Ambulance", ambulanceSchema);