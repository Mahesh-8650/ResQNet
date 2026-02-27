import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
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

    dateOfBirth: {
      type: String,
      required: true,
    },

    bloodGroup: {
      type: String,
      required: true,
    },

    emergencyContact: {
      type: String,
      required: true,
    },

    role: {
      type: String,
      default: "citizen",
    }
  },
  { timestamps: true }
);

export default mongoose.model("User", userSchema);