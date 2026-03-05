import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'citizen_map_page.dart';

class CitizenRequestStatusPage extends StatefulWidget {
  final String phone;
  final double citizenLat;
  final double citizenLng;

  const CitizenRequestStatusPage({
    super.key,
    required this.phone,
    required this.citizenLat,
    required this.citizenLng,
  });

  @override
  State<CitizenRequestStatusPage> createState() =>
      _CitizenRequestStatusPageState();
}

class _CitizenRequestStatusPageState extends State<CitizenRequestStatusPage> {

  final String baseUrl =
      "https://resqnet-backend-1xe3.onrender.com";

  Timer? timer;

  bool loading = true;

  String status = "";

  String driverName = "";
  String vehicleNumber = "";
  String hospitalName = "";
  double hospitalLat = 0;
  double hospitalLng = 0;

  @override
  void initState() {
    super.initState();

    fetchStatus();

    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => fetchStatus(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /* ================= FETCH STATUS ================= */

  Future<void> fetchStatus() async {
    try {

      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/citizen-emergency/status/${widget.phone}",
        ),
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        setState(() {

          loading = false;

          status = data["status"] ?? "pending";

          driverName =
              data["ambulance"]?["fullName"] ?? "";

          vehicleNumber =
              data["ambulance"]?["vehicleNumber"] ?? "";

          hospitalName =
              data["hospital"]?["hospitalName"] ?? "";
              
          print("Hospital data: ${data["hospital"]}");
          if (data["hospital"]?["location"]?["coordinates"] != null) {

  hospitalLng =
      data["hospital"]["location"]["coordinates"][0];

  hospitalLat =
      data["hospital"]["location"]["coordinates"][1];
}
        });
      }

    } catch (e) {

      setState(() {
        loading = false;
      });

    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(

        appBar: AppBar(
          title: const Text("Emergency Status"),
          backgroundColor: Colors.red,
        ),

        body: Center(

          child: loading || status.isEmpty
              ? const CircularProgressIndicator()

              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const Icon(
                        Icons.local_hospital,
                        size: 80,
                        color: Colors.red,
                      ),

                      const SizedBox(height: 20),

                      /// WAITING FOR DRIVER
                      if (status == "pending" || status.isEmpty || status == "offered") ...[
                        const Text(
                          "🚑 Requesting Ambulance...",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "Finding nearest driver...",
                          style: TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 30),

                        const CircularProgressIndicator(),
                      ],

                      /// DRIVER ASSIGNED
                      if (status == "assigned") ...[
                        const Text(
                          "🚑 Ambulance Assigned",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 25),

                        Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 10),
            Text("Driver: $driverName"),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.local_shipping),
            const SizedBox(width: 10),
            Text("Vehicle: $vehicleNumber"),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.local_hospital),
            const SizedBox(width: 10),
            Text("Hospital: $hospitalName"),
          ],
        ),
      ],
    ),
  ),
),

const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    onPressed: () {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CitizenMapPage(
            citizenLat: widget.citizenLat,
            citizenLng: widget.citizenLng,
            hospitalLat: hospitalLat,
            hospitalLng: hospitalLng,
          ),
        ),
      );

    },
    child: const Text(
      "Track Ambulance",
      style: TextStyle(fontSize: 16),
    ),
  ),
),
                      ],

                    ],
                  ),
                ),
        ),
      ),
    );
  }
}