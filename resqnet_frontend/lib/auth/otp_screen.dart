import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../hospital/hospital_home_screen.dart';
import '../ambulance/ambulance_home_screen.dart';
import '../citizen/citizen_home_page.dart';


class OtpScreen extends StatefulWidget {
  final String phone;
  final bool isRegisterFlow;

  const OtpScreen({
    super.key,
    required this.phone,
    this.isRegisterFlow = true,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _secondsRemaining = 120;
  Timer? _timer;

  final String baseUrl =
      "https://resqnet-backend-1xe3.onrender.com";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  /* ================= VERIFY OTP ================= */

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      _showDialog("Invalid OTP", "Please enter complete 6-digit OTP.");
      return;
    }

    if (_secondsRemaining == 0) {
      _showDialog("OTP Expired", "Please request a new OTP.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 Request permission once
      await FirebaseMessaging.instance.requestPermission();

      // 🔥 Get FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": widget.phone,
          "otp": _otp,
          "fcmToken": fcmToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        final role = data["account"]?["role"];

        if (role == "hospital") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HospitalHomeScreen(
                hospitalName:
                    data["account"]?["hospitalName"] ?? "Hospital",
                hospitalId: data["account"]?["_id"],
              ),
            ),
          );
        }

        else if (role == "ambulance") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AmbulanceHomeScreen(
                ambulanceId: data["account"]?["_id"],
                ambulanceName:
                    data["account"]?["fullName"] ?? "Ambulance",
                vehicleNumber:
                    data["account"]?["vehicleNumber"] ?? "",
                isAvailable:
                    data["account"]?["isAvailable"] ?? false,
                isBusy:
                    data["account"]?["isBusy"] ?? false,
              ),
            ),
          );
        }

        else if (role == "citizen") {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => CitizenHomePage(
        userName: data["account"]?["fullName"] ?? "User",
        phone: data["account"]?["phone"] ?? widget.phone,
      ),
    ),
  );
}

      } else {
        _showDialog("Error", data["message"] ?? "Invalid OTP");
      }

    } catch (e) {
      _showDialog("Error", "Server connection failed");
    }

    setState(() => _isLoading = false);
  }

  /* ================= RESEND OTP ================= */

  Future<void> _resendOtp() async {
    try {
      final endpoint = widget.isRegisterFlow
          ? "$baseUrl/api/auth/resend-register-otp"
          : "$baseUrl/api/auth/send-otp";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": widget.phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _startTimer();
        _showDialog("OTP Sent", data["message"] ?? "New OTP sent.");
      } else {
        _showDialog("Error",
            data["message"] ?? "Failed to resend OTP");
      }
    } catch (e) {
      _showDialog("Error", "Server connection failed");
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Expanded(
      child: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          cursorColor: Colors.red,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              FocusScope.of(context)
                  .requestFocus(_focusNodes[index + 1]);
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context)
                  .requestFocus(_focusNodes[index - 1]);
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "OTP sent to ${widget.phone}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children:
                      List.generate(6, (index) => _buildOtpBox(index)),
                ),
                const SizedBox(height: 20),
                Text(
                  "Expires in $minutes:${seconds.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text("Verify OTP"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}