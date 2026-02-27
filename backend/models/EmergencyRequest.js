import mongoose from "mongoose";

const emergencyRequestSchema = new mongoose.Schema(
  {
    hospitalId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Hospital",
      required: true,
    },

    ambulanceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Ambulance",
      required: true,
    },

    patientName: {
      type: String,
      required: true,
    },

    emergencyType: {
      type: String,
      required: true,
    },

    status: {
      type: String,
      enum: ["pending", "accepted", "completed"],
      default: "pending",
    },
  },
  { timestamps: true }
);

export default mongoose.model("EmergencyRequest", emergencyRequestSchema);