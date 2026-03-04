import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../welcome/welcome_screen.dart';

class CitizenSettingsPage extends StatefulWidget {
  final String citizenId;
  final String userName;
  final String email;
  final String phone;
  final String bloodGroup;
  final String dob;
  final String emergencyContact;

  const CitizenSettingsPage({
    super.key,
    required this.citizenId,
    required this.userName,
    required this.email,
    required this.phone,
    required this.bloodGroup,
    required this.dob,
    required this.emergencyContact,
  });

  @override
  State<CitizenSettingsPage> createState() =>
      _CitizenSettingsPageState();
}

class _CitizenSettingsPageState extends State<CitizenSettingsPage> {

  final String baseUrl =
      "https://resqnet-backend-1xe3.onrender.com";

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();

  String selectedBloodGroup = "O+";
  String selectedCountryCode = "+91";
  DateTime? selectedDob;

  bool isEditing = false;

  final List<String> bloodGroups = [
    "A+","A-","B+","B-","AB+","AB-","O+","O-"
  ];

  final List<String> countryCodes = [
    "+91","+1","+44","+971"
  ];

  @override
  void initState() {
    super.initState();

    nameController.text = widget.userName;
    emailController.text = widget.email;
    phoneController.text = widget.phone;

    /* ================= BLOOD GROUP ================= */

    if (widget.bloodGroup.isNotEmpty) {
      selectedBloodGroup = widget.bloodGroup;
    }

    /* ================= DOB ================= */

    if (widget.dob.isNotEmpty) {
      try {
        final parts = widget.dob.split("-");
        selectedDob = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } catch (_) {}
    }

    /* ================= EMERGENCY CONTACT ================= */

    if (widget.emergencyContact.contains(" ")) {
      final parts = widget.emergencyContact.split(" ");
      selectedCountryCode = parts[0];
      emergencyController.text = parts[1];
    } else {
      emergencyController.text = widget.emergencyContact;
    }
  }

  /* ===================================================== */
  /* DATE PICKER */
  /* ===================================================== */

  Future<void> _pickDate() async {

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDob = picked;
      });
    }
  }

  String get formattedDob {

    if (selectedDob == null) return "";

    return "${selectedDob!.day}-${selectedDob!.month}-${selectedDob!.year}";
  }

  /* ===================================================== */
  /* UPDATE PROFILE */
  /* ===================================================== */

  Future<void> _updateProfile() async {

    final response = await http.put(
      Uri.parse(
          "$baseUrl/api/auth/citizen/update/${widget.citizenId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": nameController.text,
        "bloodGroup": selectedBloodGroup,
        "dob": formattedDob,
        "emergencyContact":
            "$selectedCountryCode ${emergencyController.text}",
      }),
    );

    if (response.statusCode == 200) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated")),
      );

      setState(() {
        isEditing = false;
      });
    }
  }

  /* ===================================================== */
  /* PASSWORD DIALOG */
  /* ===================================================== */

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
                            obscureConfirm = !obscureConfirm;
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

                    final password = newController.text;
                    final confirm = confirmController.text;

                    final passwordRegex = RegExp(
                        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');

                    if (!passwordRegex.hasMatch(password)) {

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
                            content:
                                Text("Passwords do not match")),
                      );

                      return;
                    }

                    final response = await http.put(
                      Uri.parse(
                          "$baseUrl/api/auth/citizen/change-password/${widget.citizenId}"),
                      headers: {
                        "Content-Type": "application/json"
                      },
                      body: jsonEncode({
                        "newPassword": password,
                      }),
                    );

                    if (response.statusCode == 200) {

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content: Text("Password Updated")),
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

  /* ===================================================== */
  /* LOGOUT */
  /* ===================================================== */

  void _logout() {

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  /* ===================================================== */
  /* UI */
  /* ===================================================== */

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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "User Information",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            _buildField("Full Name", nameController, isEditing),
            _buildField("Email", emailController, false),
            _buildField("Phone", phoneController, false),

            /* ================= BLOOD GROUP ================= */

            const Text("Blood Group"),
            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: selectedBloodGroup,
              items: bloodGroups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: isEditing
                  ? (value) {
                      setState(() {
                        selectedBloodGroup = value!;
                      });
                    }
                  : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: isEditing ? Colors.white : Colors.grey.shade300,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /* ================= DOB ================= */

            const Text("Date of Birth"),
            const SizedBox(height: 6),

            GestureDetector(
              onTap: isEditing ? _pickDate : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isEditing ? Colors.white : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  formattedDob.isEmpty
                      ? "Select Date"
                      : formattedDob,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /* ================= EMERGENCY CONTACT ================= */

            const Text("Emergency Contact"),
            const SizedBox(height: 6),

            Row(
              children: [

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isEditing ? Colors.white : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCountryCode,
                    underline: const SizedBox(),
                    items: countryCodes.map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text(code),
                      );
                    }).toList(),
                    onChanged: isEditing
                        ? (value) {
                            setState(() {
                              selectedCountryCode = value!;
                            });
                          }
                        : null,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: emergencyController,
                    readOnly: !isEditing,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isEditing ? Colors.white : Colors.grey.shade300,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (isEditing)
              Padding(
                padding:
                    const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize:
                        const Size.fromHeight(50),
                  ),
                  onPressed: _updateProfile,
                  child: const Text("Save Changes"),
                ),
              ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize:
                    const Size.fromHeight(50),
              ),
              onPressed: _showPasswordDialog,
              child:
                  const Text("Update Password"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
              fillColor: enabled ? Colors.white : Colors.grey.shade300,

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(30),
              ),

              enabledBorder: OutlineInputBorder(
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