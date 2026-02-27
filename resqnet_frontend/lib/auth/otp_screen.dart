import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../hospital/hospital_home_screen.dart';

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

  final String baseUrl = "http://192.168.1.56:5000";

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
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone": widget.phone,
        "otp": _otp,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {

      // 🔥 Extract role
      final role = data["account"]?["role"];

      // 🔥 Extract hospital name
      final hospitalName =
          data["account"]?["hospitalName"] ?? "Hospital";

      // 🔥 Extract hospital ID (VERY IMPORTANT)
      final hospitalId = data["account"]?["_id"];

      if (role == "hospital") {
        final hospitalId = data["account"]["_id"];
        final hospitalAddress = data["account"]["address"];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HospitalHomeScreen(
              hospitalName: hospitalName,
              hospitalId: hospitalId,   // ✅ Pass ID
            ),
          ),
        );
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
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
        _showDialog("Error", data["message"] ?? "Failed to resend OTP");
      }
    } catch (e) {
      _showDialog("Error", "Server connection failed");
    }
  }

  /* ================= DIALOG ================= */

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /* ================= OTP BOX ================= */

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

  /* ================= UI ================= */

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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
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
                  children: List.generate(
                    6,
                    (index) => _buildOtpBox(index),
                  ),
                ),

                const SizedBox(height: 20),

                _secondsRemaining > 0
                    ? Text(
                        "Expires in $minutes:${seconds.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey),
                      )
                    : TextButton(
                        onPressed: _resendOtp,
                        child: const Text(
                          "Resend OTP",
                          style: TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading || _secondsRemaining == 0
                            ? null
                            : _verifyOtp,
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