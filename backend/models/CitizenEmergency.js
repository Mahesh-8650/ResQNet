import mongoose from "mongoose";

const citizenEmergencySchema = new mongoose.Schema(
  {
    // 🔥 Patient Location (GeoJSON format for nearest search)
    patientLocation: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },

    patientName: {
      type: String,
      required: true,
      trim: true,
    },
    patientAddress: {
  type: String,
  default: "",
},
    patientPhone: {
      type: String,
      required: true,
    },

    emergencyType: {
      type: String,
      required: true,
      trim: true,
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
    
    offeredAt: {
  type: Date,
  default: null,
},

acceptedAt: {
  type: Date,
  default: null,
},

completedAt: {
  type: Date,
  default: null,
},

completedBy: {
  type: mongoose.Schema.Types.ObjectId,
  ref: "Ambulance",
},

responseTimeInSeconds: {
  type: Number,
  default: 0,
},

distanceCoveredKm: {
  type: Number,
  default: 0,
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

// 🔥 Required for nearest driver search
citizenEmergencySchema.index({ patientLocation: "2dsphere" });

export default mongoose.model("CitizenEmergency", citizenEmergencySchema);