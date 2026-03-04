import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'citizen_request_status_page.dart';

class CitizenHomePage extends StatefulWidget {
  final String userName;
  final String phone;

  const CitizenHomePage({
    super.key,
    required this.userName,
    required this.phone,
  });

  @override
  State<CitizenHomePage> createState() => _CitizenHomePageState();
}

class _CitizenHomePageState extends State<CitizenHomePage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  bool isSendingRequest = false;

  double? latitude;
  double? longitude;

  String selectedHospital = "Not Selected";
  String? selectedHospitalId;

  List<Map<String, String>> hospitals = [];

  final String baseUrl =
      "https://resqnet-backend-1xe3.onrender.com";

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..repeat();

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
            "distance": "${h["distance"].toStringAsFixed(1)} km",
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

    await getLocation();

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not available")),
      );
      return;
    }

    try {

      final response = await http.post(
        Uri.parse("$baseUrl/api/citizen-emergency/create"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "patientName": widget.userName,
          "patientPhone": widget.phone,
          "emergencyType": "General Emergency",
          "latitude": latitude,
          "longitude": longitude,
          "hospitalId": selectedHospitalId,
        }),
      );

      if (response.statusCode == 201) {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CitizenRequestStatusPage(
              phone: widget.phone,
            ),
          ),
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send emergency request")),
        );

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server connection failed")),
      );

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              color: Colors.red,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Icon(Icons.arrow_back, color: Colors.white),

                  Text(
                    "ResQNet",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),

                  Icon(Icons.settings, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// WELCOME
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Welcome, ${widget.userName.toUpperCase()}",
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