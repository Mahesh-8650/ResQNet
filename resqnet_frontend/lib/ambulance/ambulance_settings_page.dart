import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../welcome/welcome_screen.dart';

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

  bool isEditing = false;
  bool isLoading = true;
  String status = "";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  /* ================= FETCH PROFILE ================= */

  Future<void> _fetchProfile() async {
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
  }

  /* ================= UPDATE PROFILE ================= */

  Future<void> _updateProfile() async {
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
        const SnackBar(content: Text("Profile Updated")),
      );
      setState(() => isEditing = false);
    }
  }

  /* ================= PASSWORD DIALOG ================= */

  void _showPasswordDialog() {
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Update Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            obscureConfirm =
                                !obscureConfirm;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("Update"),
                  onPressed: () async {

                    final password =
                        newController.text;
                    final confirm =
                        confirmController.text;

                    final passwordRegex =
                        RegExp(
                            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');

                    if (!passwordRegex
                        .hasMatch(password)) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Password must be 8+ chars with uppercase, lowercase, number & special character")),
                      );
                      return;
                    }

                    if (password != confirm) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Passwords do not match")),
                      );
                      return;
                    }

                    final response = await http.put(
                      Uri.parse(
                          "$baseUrl/api/auth/ambulance/change-password/${widget.ambulanceId}"),
                      headers: {
                        "Content-Type":
                            "application/json"
                      },
                      body: jsonEncode({
                        "newPassword": password,
                      }),
                    );

                    if (response.statusCode ==
                        200) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Password Updated")),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Settings"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Profile",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildField("Full Name",
                      nameController, isEditing),
                  _buildField("Email",
                      emailController, false),
                  _buildField("Phone",
                      phoneController, false),
                  _buildField("License Number",
                      licenseController, isEditing),
                  _buildField("Vehicle Number",
                      vehicleController, isEditing),

                  const SizedBox(height: 10),

                  Container(
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(
                              20),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text("Status"),
                        Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight:
                                  FontWeight.bold),
                        )
                      ],
                    ),
                  ),

                  if (isEditing)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                              top: 20),
                      child: ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red,
                          minimumSize:
                              const Size
                                  .fromHeight(50),
                        ),
                        onPressed: _updateProfile,
                        child: const Text(
                            "Save Changes"),
                      ),
                    ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blue,
                      minimumSize:
                          const Size
                              .fromHeight(50),
                    ),
                    onPressed:
                        _showPasswordDialog,
                    child:
                        const Text("Update Password"),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red,
                      minimumSize:
                          const Size
                              .fromHeight(50),
                    ),
                    onPressed: _logout,
                    child:
                        const Text("Logout"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String label,
      TextEditingController controller,
      bool enabled) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: !enabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade300,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(30),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}