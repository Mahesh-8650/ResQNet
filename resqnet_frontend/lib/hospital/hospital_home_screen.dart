import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'incoming_requests_screen.dart';
import 'completed_requests_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../welcome/welcome_screen.dart';

class HospitalHomeScreen extends StatefulWidget {
  final String hospitalName;
  final String hospitalId;

  const HospitalHomeScreen({
    super.key,
    required this.hospitalName,
    required this.hospitalId,
  });

  @override
  State<HospitalHomeScreen> createState() => _HospitalHomeScreenState();
}

class _HospitalHomeScreenState extends State<HospitalHomeScreen> {
  final String baseUrl = "https://resqnet-backend-1xe3.onrender.com";

  int icuBeds = 0;
  int generalBeds = 0;
  bool oxygenAvailable = false;
  bool emergencyAvailable = false;
  String hospitalAddress = "";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHospitalData();
  }

  Future<void> fetchHospitalData() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/auth/hospital/${widget.hospitalId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          icuBeds = data["icuBedsAvailable"] ?? 0;
          generalBeds = data["generalBedsAvailable"] ?? 0;
          oxygenAvailable = data["oxygenAvailable"] ?? false;
          emergencyAvailable = data["emergencyAvailable"] ?? false;
          hospitalAddress = data["address"] ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  Future<void> updateResources() async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/auth/hospital/update-resources"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "hospitalId": widget.hospitalId,
          "icuBedsAvailable": icuBeds,
          "generalBedsAvailable": generalBeds,
          "oxygenAvailable": oxygenAvailable,
          "emergencyAvailable": emergencyAvailable,
        }),
      );

      if (response.statusCode == 200) {
        await fetchHospitalData();
        showMessage("Success", "Resources updated successfully");
      }
    } catch (e) {
      showMessage("Error", "Server connection failed");
    }
  }

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

  void showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildResourceCard(),
              const SizedBox(height: 20),
              _buildUpdateButton(),
              const SizedBox(height: 30),
              _buildManagementSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hospital Dashboard",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            widget.hospitalName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hospitalAddress,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _resourceTile(Icons.local_hospital, "ICU Beds",
                        icuBeds.toString(), Colors.blue)),
                const SizedBox(width: 15),
                Expanded(
                    child: _resourceTile(Icons.bed, "General Beds",
                        generalBeds.toString(), Colors.orange)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                    child: _resourceTile(
                        Icons.air,
                        "Oxygen",
                        oxygenAvailable ? "Available" : "Not Available",
                        Colors.green)),
                const SizedBox(width: 15),
                Expanded(
                    child: _resourceTile(
                        Icons.warning,
                        "Emergency",
                        emergencyAvailable ? "Active" : "Inactive",
                        Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourceTile(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 15),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _showUpdateDialog,
          child: const Text("Update Resources",
              style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hospital Management",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          _buildManagementTile(
            Icons.notifications,
            "Incoming Requests",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      IncomingRequestsScreen(hospitalId: widget.hospitalId),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _buildManagementTile(
            Icons.check_circle,
            "Completed Cases",
            iconColor: Colors.green, // ✅ NOW WORKS
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CompletedRequestsScreen(hospitalId: widget.hospitalId),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    onPressed: _logout,
    child: const Text("Logout"),
  ),
),
        ],
      ),
    );
  }

  Widget _buildManagementTile(
    IconData icon,
    String title, {
    Color iconColor = const Color(0xFFD32F2F),
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor), // ✅ FIXED HERE
            const SizedBox(width: 15),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 16)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _showUpdateDialog() {
    final icuController =
        TextEditingController(text: icuBeds.toString());
    final generalController =
        TextEditingController(text: generalBeds.toString());

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Update Resources"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: icuController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: "ICU Beds"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: generalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: "General Beds"),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text("Oxygen Available"),
                      value: oxygenAvailable,
                      onChanged: (val) {
                        setDialogState(() {
                          oxygenAvailable = val;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Emergency Active"),
                      value: emergencyAvailable,
                      onChanged: (val) {
                        setDialogState(() {
                          emergencyAvailable = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      icuBeds =
                          int.tryParse(icuController.text) ?? 0;
                      generalBeds =
                          int.tryParse(generalController.text) ?? 0;
                    });
                    Navigator.pop(context);
                    updateResources();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}