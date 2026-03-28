import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'citizen_request_status_page.dart';
import 'citizen_settings_page.dart';

class CitizenHomePage extends StatefulWidget {
  final String citizenId;
  final String userName;
  final String email;
  final String phone;
  final String bloodGroup;
  final String dob;
  final String emergencyContact;

  const CitizenHomePage({
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
  State<CitizenHomePage> createState() => _CitizenHomePageState();
}

class _CitizenHomePageState extends State<CitizenHomePage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  bool isSendingRequest = false;
  String userName = "";
  String phone = "";

  double? latitude;
  double? longitude;

  String selectedHospital = "Not Selected";
  String? selectedHospitalId;

  List<Map<String, String>> hospitals = [];

  final String baseUrl =
      "https://resqnet-oe5z.onrender.com";

  
  Future<void> loadUserData() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    userName = prefs.getString("citizenName") ?? widget.userName;
    phone = prefs.getString("citizenPhone") ?? widget.phone;
  });
}

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..repeat();

    loadUserData();
    getLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /* ================= FETCH HOSPITALS ================= */

  Future<void> fetchHospitals() async {

    if (latitude == null || longitude == null) return;

    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/hospitals/nearest?latitude=$latitude&longitude=$longitude",
      ),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      print("Hospital API response : $data");

      setState(() {
        hospitals = List<Map<String, String>>.from(
          data["hospitals"].map((h) => {
            "id": h["_id"].toString(),
            "name": h["hospitalName"].toString(),
            "location": h["address"].toString(),
            "distance": "${double.parse(h["distance"].toString()).toStringAsFixed(1)} km",
          }),
        );
      });
    }
  }

  /* ================= GET LOCATION ================= */

  Future<void> getLocation() async {

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission permanently denied")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitude = position.latitude;
    longitude = position.longitude;

    print("User latitude : $latitude");
    print("User longitude : $longitude");

    await fetchHospitals();
  }

  /* ================= SOS REQUEST ================= */

Future<void> triggerSOS() async {

  if (isSendingRequest) return;

  setState(() {
    isSendingRequest = true;
  });

  try {

    await getLocation();

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not available")),
      );

      setState(() => isSendingRequest = false); // ✅ FIX
      return;
    }

    String address = "";

    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=AIzaSyD4mbUNGRXLThlB54YDgH5J7hdXtVLB8WU";

    final geoResponse = await http.get(Uri.parse(url));

    if (geoResponse.statusCode == 200) {
      final data = jsonDecode(geoResponse.body);

      if (data["results"].isNotEmpty) {
        address = data["results"][0]["formatted_address"];
      }
    }

    final response = await http.post(
      Uri.parse("$baseUrl/api/citizen-emergency/create"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "patientName": userName,
        "patientPhone": phone,
        "emergencyType": "General Emergency",
        "latitude": latitude,
        "longitude": longitude,
        "patientAddress": address,
        "hospitalId": selectedHospitalId,
      }),
    );

    if (response.statusCode == 201) {

      final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("hasActiveRequest", true);
  await prefs.setString("requestPhone", phone);
  await prefs.setDouble("citizenLat", latitude!);
  await prefs.setDouble("citizenLng", longitude!);


      setState(() => isSendingRequest = false); // ✅ FIX

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CitizenRequestStatusPage(
            phone: phone,
            citizenLat: latitude!,
            citizenLng: longitude!,
          ),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send emergency request")),
      );

      setState(() => isSendingRequest = false); // ✅ FIX
    }

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Server connection failed")),
    );

    setState(() => isSendingRequest = false); // ✅ FIX
  }
}

  /* ================= OPEN HOSPITAL PAGE ================= */

  Future<void> openHospitalSelectionPage() async {

  if (hospitals.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Hospitals are still loading. Please wait...")),
    );
    return;
  }

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HospitalSelectionPage(
        hospitals: hospitals,
      ),
    ),
  );

  if (result != null) {
    setState(() {
      selectedHospital = result["name"];
      selectedHospitalId = result["id"];
    });
  }
}

  @override
  Widget build(BuildContext context) {

    const Color baseRedColor = Color(0xFFFF0000);

    return Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFFA8DADC),
        Color(0xFF80CBC4),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  child: Scaffold(
    backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// SIMPLE HEADER
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      // LEFT ICON (optional)
      Icon(Icons.menu, color: Colors.black),

      // TITLE
      const Text(
        "ResQNet",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),

      // SETTINGS
      IconButton(
        icon: const Icon(Icons.settings, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CitizenSettingsPage(
                citizenId: widget.citizenId,
                userName: widget.userName,
                email: widget.email,
                phone: widget.phone,
                bloodGroup: widget.bloodGroup,
                dob: widget.dob,
                emergencyContact: widget.emergencyContact,
              ),
            ),
          );
        },
      ),
    ],
  ),
),

            const SizedBox(height: 20),

            /// WELCOME
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Welcome, ${userName.toUpperCase()}",
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            /// SELECTED HOSPITAL
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Selected Hospital: $selectedHospital",
                style: const TextStyle(fontSize: 16),
              ),
            ),

            /// SOS BUTTON
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {

                    double spread = 30 * _controller.value;
                    double opacity = 0.7 * (1 - _controller.value);

                    return Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(
                                (opacity * 255).round(),
                                255,
                                0,
                                0),
                            spreadRadius: spread,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isSendingRequest ? null : triggerSOS,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: baseRedColor,
                          shape: const CircleBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          "SOS",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            /// SELECT HOSPITAL BUTTON
            Center(
              child: SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: openHospitalSelectionPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    "Select Hospital",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

          ],
        ),
      ),
      bottomNavigationBar: Container(
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
      ),
    ],
  ),
  child: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
    selectedItemColor: Colors.red,
    unselectedItemColor: Colors.grey,
    currentIndex: 0,
  onTap: (index) async {
    if (index == 1) {
      final prefs = await SharedPreferences.getInstance();

      bool hasRequest = prefs.getBool("hasActiveRequest") ?? false;

      if (!hasRequest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No active request")),
        );
        return;
      }

      String phone = prefs.getString("requestPhone") ?? "";
      double lat = prefs.getDouble("citizenLat") ?? 0;
      double lng = prefs.getDouble("citizenLng") ?? 0;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CitizenRequestStatusPage(
            phone: phone,
            citizenLat: lat,
            citizenLng: lng,
          ),
        ),
      );
    }
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Home",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long),
      label: "Request",
    ),
  ],
),//hii
  ),
  ),
    );
  }
}

/* ===================================================== */
/* ================= HOSPITAL PAGE ====================== */
/* ===================================================== */

class HospitalSelectionPage extends StatelessWidget {

  final List<Map<String, String>> hospitals;

  const HospitalSelectionPage({
    super.key,
    required this.hospitals,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Hospital"),
        backgroundColor: Colors.red,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: hospitals.length,
        itemBuilder: (context, index) {

          final hospital = hospitals[index];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [

                  const Icon(
                    Icons.local_hospital,
                    color: Colors.red,
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          hospital["name"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        Text("📍 ${hospital["location"] ?? ""}"),

                        Text("🚗 ${hospital["distance"] ?? ""}"),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: 90,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, hospital);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        "Select",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}