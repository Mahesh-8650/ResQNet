// KEEP YOUR IMPORTS SAME
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:country_picker/country_picker.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() =>
      _RegisterUserScreenState();
}

class _RegisterUserScreenState
    extends State<RegisterUserScreen> {

  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _emergency = TextEditingController();

  Country _country = Country.parse("IN");
  String? _bloodGroup;

  bool _loading = false;
  bool _obscurePassword = true;

  final List<String> bloodGroups = [
    "A+","A-","B+","B-","AB+","AB-","O+","O-"
  ];

  bool _isStrong(String value) {
    final regex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');
    return regex.hasMatch(value);
  }

  bool _isValidEmail(String value) {
    final regex =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(value);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _dob.text =
          "${picked.day.toString().padLeft(2,'0')}-"
          "${picked.month.toString().padLeft(2,'0')}-"
          "${picked.year}";
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (c) {
        setState(() => _country = c);
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final fullPhone =
        "+${_country.phoneCode}${_phone.text.trim()}";

    final fullEmergency =
        "+${_country.phoneCode}${_emergency.text.trim()}";

    try {
      final res = await http.post(
        Uri.parse(
            "https://resqnet-backend-1xe3.onrender.com/api/auth/register/user"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": _name.text.trim(),
          "email": _email.text.trim(),
          "password": _password.text.trim(),
          "phone": fullPhone,
          "dateOfBirth": _dob.text.trim(),
          "bloodGroup": _bloodGroup,
          "emergencyContact": fullEmergency,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phone: fullPhone,
              isRegisterFlow: true,
            ),
          ),
        );
      } else {
        _showDialog("Error", data["message"]);
      }
    } catch (e) {
      _showDialog("Error", "Server connection failed");
    }

    setState(() => _loading = false);
  }

  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Widget _phoneField(
      TextEditingController controller, String label) {
    return Row(
      children: [
        GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EDF7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text("+${_country.phoneCode}"),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down,
                    size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: label),
            validator: (v) =>
                v!.isEmpty ? "Enter $label" : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar:
          AppBar(title: const Text("User Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                TextFormField(
                  controller: _name,
                  decoration:
                      const InputDecoration(labelText: "Full Name"),
                  validator: (v) =>
                      v!.isEmpty ? "Enter name" : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _email,
                  decoration:
                      const InputDecoration(labelText: "Email"),
                  validator: (v) =>
                      !_isValidEmail(v!)
                          ? "Enter valid email"
                          : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (v) =>
                      !_isStrong(v!)
                          ? "Min 8 chars, upper, lower, number & special char"
                          : null,
                ),

                const SizedBox(height: 15),

                _phoneField(_phone, "Phone"),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _dob,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration:
                      const InputDecoration(labelText: "Date of Birth"),
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: _bloodGroup,
                  decoration:
                      const InputDecoration(labelText: "Blood Group"),
                  items: bloodGroups
                      .map((bg) => DropdownMenuItem(
                          value: bg,
                          child: Text(bg)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _bloodGroup = v),
                ),

                const SizedBox(height: 15),

                _phoneField(
                    _emergency, "Emergency Contact"),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _loading ? null : _register,
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text("Register"),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}