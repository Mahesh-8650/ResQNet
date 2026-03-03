import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../welcome/welcome_screen.dart'; // change if your path differs

class AmbulanceSettingsPage extends StatefulWidget {
  final String ambulanceId;

  const AmbulanceSettingsPage({
    super.key,
    required this.ambulanceId,
  });

  @override
  State<AmbulanceSettingsPage> createState() =>
      _AmbulanceSettingsPageState();
}

class _AmbulanceSettingsPageState
    extends State<AmbulanceSettingsPage> {

  final String baseUrl =
      "https://resqnet-backend-1xe3.onrender.com";

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final licenseController = TextEditingController();
  final vehicleController = TextEditingController();

  final newPasswordController = TextEditingController();
  final confirmPasswordController =
      TextEditingController();

  bool isEditing = false;
  bool isLoading = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  String status = "";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  /* ================= FETCH PROFILE ================= */

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse(
            "$baseUrl/api/auth/ambulance/${widget.ambulanceId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          nameController.text = data["fullName"] ?? "";
          emailController.text = data["email"] ?? "";
          phoneController.text = data["phone"] ?? "";
          licenseController.text =
              data["licenseNumber"] ?? "";
          vehicleController.text =
              data["vehicleNumber"] ?? "";
          status = data["status"] ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /* ================= UPDATE PROFILE ================= */

  Future<void> _updateProfile() async {
    try {
      final response = await http.put(
        Uri.parse(
            "$baseUrl/api/auth/ambulance/update/${widget.ambulanceId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": nameController.text,
          "licenseNumber": licenseController.text,
          "vehicleNumber": vehicleController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Profile updated successfully")),
        );
        setState(() => isEditing = false);
      }
    } catch (_) {}
  }

  /* ================= CHANGE PASSWORD ================= */

  Future<void> _changePassword() async {

    final password = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');

    if (!passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Password must be 8+ chars with uppercase, lowercase, number & special character")),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse(
            "$baseUrl/api/auth/ambulance/change-password/${widget.ambulanceId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "newPassword": password,
        }),
      );

      if (response.statusCode == 200) {
        newPasswordController.clear();
        confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Password updated successfully")),
        );
      }
    } catch (_) {}
  }

  /* ================= LOGOUT ================= */

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Settings"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.close : Icons.edit,
            ),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  _buildField(
                      "Full Name",
                      nameController,
                      isEditing),

                  _buildField(
                      "Email",
                      emailController,
                      false),

                  _buildField(
                      "Phone",
                      phoneController,
                      false),

                  _buildField(
                      "License Number",
                      licenseController,
                      isEditing),

                  _buildField(
                      "Vehicle Number",
                      vehicleController,
                      isEditing),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text("Status: "),
                      Chip(
                        label: Text(status),
                        backgroundColor:
                            status == "approved"
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                      ),
                    ],
                  ),

                  if (isEditing)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 15),
                      child: ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red,
                          minimumSize:
                              const Size.fromHeight(
                                  50),
                        ),
                        onPressed: _updateProfile,
                        child: const Text(
                            "Save Changes"),
                      ),
                    ),

                  const Divider(height: 40),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Change Password",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildPasswordField(
                      "New Password",
                      newPasswordController,
                      obscureNew, () {
                    setState(() {
                      obscureNew = !obscureNew;
                    });
                  }),

                  _buildPasswordField(
                      "Confirm Password",
                      confirmPasswordController,
                      obscureConfirm, () {
                    setState(() {
                      obscureConfirm =
                          !obscureConfirm;
                    });
                  }),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blue,
                      minimumSize:
                          const Size.fromHeight(50),
                    ),
                    onPressed: _changePassword,
                    child:
                        const Text("Update Password"),
                  ),

                  const Divider(height: 40),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red,
                      minimumSize:
                          const Size.fromHeight(50),
                    ),
                    onPressed: _logout,
                    child: const Text("Logout"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController controller,
      bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        readOnly: !enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor:
              enabled ? Colors.white : Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool obscure,
      VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}