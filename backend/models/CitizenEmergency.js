import mongoose from "mongoose";

const citizenEmergencySchema = new mongoose.Schema(
  {
    patientLocation: {
      latitude: Number,
      longitude: Number,
    },

    patientName: {
      type: String,
      required: true,
    },

    emergencyType: {
      type: String,
      required: true,
    },

    hospitalId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Hospital",
      default: null, // null if user didn’t select
    },

    selectedBy: {
      type: String,
      enum: ["user", "system"],
      default: null,
    },

    ambulanceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Ambulance",
      default: null,
    },

    status: {
      type: String,
      enum: [
        "pending",
        "offered",
        "assigned",
        "completed",
      ],
      default: "pending",
    },
  },
  { timestamps: true }
);

export default mongoose.model("CitizenEmergency", citizenEmergencySchema);