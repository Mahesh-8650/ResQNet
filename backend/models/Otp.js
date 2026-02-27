import mongoose from "mongoose";

const otpSchema = new mongoose.Schema(
  {
    phone: String,
    otp: String,
    expiresAt: Date,
    registrationData: Object, // 🔥 important
  },
  { timestamps: true }
);

export default mongoose.model("Otp", otpSchema);