import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../welcome/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<void> _logout() async {

  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.clear();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const WelcomeScreen(),
    ),
    (route) => false,
  );
}

@override
void dispose() {
  nameController.dispose();
  emailController.dispose();
  phoneController.dispose();
  licenseController.dispose();
  vehicleController.dispose();
  super.dispose();
}

/* ================= UI ================= */

@override
Widget build(BuildContext context) {
  return Scaffold(

    body: Container(

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFD9F3F1),
            Color(0xFF77C7C9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),

      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [

                    /// HEADER
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [

                          Row(
                            children: [

                              const SizedBox(width: 40),

                              const Text(
                                "Settings",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

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
                    ),

                    /// PROFILE INFO

                    _infoCard(Icons.person, "Full Name",
                        nameController, isEditing),

                    _infoCard(Icons.email, "Email",
                        emailController, false),

                    _infoCard(Icons.phone, "Phone",
                        phoneController, false),

                    _infoCard(Icons.badge, "License Number",
                        licenseController, isEditing),

                    _infoCard(Icons.local_shipping,
                        "Vehicle Number",
                        vehicleController,
                        isEditing),

                    _statusCard(),

                    const SizedBox(height: 20),

                    /// SAVE CHANGES
                    if (isEditing)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),
                            ),
                            onPressed: _updateProfile,
                            child:
                                const Text("Save Changes"),
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    /// UPDATE PASSWORD
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.lock),
                          label:
                              const Text("Update Password"),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF009688),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                            ),
                          ),
                          onPressed: _showPasswordDialog,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// LOGOUT
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text("Logout"),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFF44336),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                            ),
                          ),
                          onPressed: _logout,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    ),
  );
}

Widget _infoCard(
  IconData icon,
  String title,
  TextEditingController controller,
  bool editable,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    padding: const EdgeInsets.all(16),

    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4)
      ],
    ),

    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        /// ICON
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.red.withOpacity(0.1),
          child: Icon(icon, color: Colors.red),
        ),

        const SizedBox(width: 16),

        /// FIELD
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// LABEL
             Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 6),

              /// INPUT BOX
              TextField(
                controller: controller,
                readOnly: !editable,

                decoration: InputDecoration(
                  filled: true,

                  /// editable fields become white
                  fillColor: isEditing && editable
                      ? Colors.white
                      : Colors.grey.shade200,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _statusCard() {
  return Container(
    margin:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    padding: const EdgeInsets.all(16),

    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4)
      ],
    ),

    child: Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [

        const Text(
          "Status",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          status.toUpperCase(),
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
    }