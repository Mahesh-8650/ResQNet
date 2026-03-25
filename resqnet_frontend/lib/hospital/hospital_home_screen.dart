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
  int _selectedIndex = 1;

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
      backgroundColor: Colors.transparent,
      body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFFB2DFDB),
        Color(0xFF80CBC4),
        Color(0xFF4DB6AC),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  child: _selectedIndex == 1
    ? _buildHomePage()
    : _selectedIndex == 0
        ? IncomingRequestsScreen(hospitalId: widget.hospitalId)
        : CompletedRequestsScreen(hospitalId: widget.hospitalId),
      ),
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: _selectedIndex,
  selectedItemColor: Colors.red,
  unselectedItemColor: Colors.grey,
  onTap: (index) {
    setState(() {
      _selectedIndex = index;
    });
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.notifications),
      label: "Requests",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Home",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.check_circle),
      label: "Completed",
    ),
  ],
),
    );
  }

  Widget _topBar() {
  return const Padding(
    padding: EdgeInsets.symmetric(vertical: 10), // 👈 reduced
    child: Center(
      child: Text(
        "Hospital Dashboard",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600, // 👈 better than bold
          letterSpacing: 0.5, // 👈 premium feel
        ),
      ),
    ),
  );
}

 Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.9),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Row(
          children: [

            /// TEXT
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      widget.hospitalName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_pin,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hospitalAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// IMAGE (FINAL FIX)
            Expanded(
  flex: 2,
  child: Transform.scale(
    scale: 1.25, // 🔥 increase until it looks perfect
    alignment: Alignment.centerRight,
    child: Image.asset(
      "assets/images/hospital_bg.png",
      fit: BoxFit.cover,
    ),
  ),
),
          ],
        ),
      ),
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
          borderRadius: BorderRadius.circular(28),
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 15,
    offset: const Offset(0, 6),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _resourceTile(
    IconData icon, String label, String value, Color color) {
  return Container(
    height: 130, // 🔥 FIXED SIZE
    padding: const EdgeInsets.all(10), // 🔥 reduced
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
  value,
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
  ),
),

const SizedBox(height: 4),

Text(
  label,
  style: const TextStyle(
    fontSize: 12,
    color: Colors.black54,
  ),
),
        const Spacer(),
      ],
    ),
  );
}

  Widget _buildUpdateButton() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30),
    child: SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _showUpdateDialog, // ✅ functionality intact

        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // 🔥 important for gradient
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // 🔥 pill shape
          ),
          elevation: 0, // cleaner look
          backgroundColor: Colors.transparent, // 🔥 required
        ),

        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFFF3B30)],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Center(
            child: Text(
              "Update Resources",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
          Row(
  children: [
    const Text(
      "Hospital Management",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ],
),
          const SizedBox(height: 15),

          _buildManagementTile(
            Icons.notifications,
            "Incoming Requests",
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),

          const SizedBox(height: 10),

          _buildManagementTile(
            Icons.check_circle,
            "Completed Cases",
            iconColor: Colors.green, // ✅ NOW WORKS
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
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
      height: 70, // 🔥 FIXED
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
                borderRadius: BorderRadius.circular(20),
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 10,
    offset: const Offset(0, 4),
  )
],
      ),
      child: Row(
        children: [

          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    ),
  );
}

Widget _buildHomePage() {
  return SafeArea(
    child: SingleChildScrollView(
      child: Column(
        children: [
          _topBar(),
          const SizedBox(height: 8),
          _buildHeader(),
          const SizedBox(height: 15),
          _buildResourceCard(),
          const SizedBox(height: 20),
          _buildManagementSection(),
          const SizedBox(height: 20),
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