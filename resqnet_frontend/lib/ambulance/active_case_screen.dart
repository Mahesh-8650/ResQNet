import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ambulance_map_page.dart';

class ActiveCaseScreen extends StatefulWidget {
  final String emergencyId;
  final Map<String, dynamic> emergencyData;
  final String ambulanceId;

  const ActiveCaseScreen({
    super.key,
    required this.emergencyId,
    required this.emergencyData,
    required this.ambulanceId,
  });

  @override
  State<ActiveCaseScreen> createState() =>
      _ActiveCaseScreenState();
}

class _ActiveCaseScreenState
    extends State<ActiveCaseScreen> {

  final String baseUrl =
      "https://resqnet-backend-1xe3.onrender.com";

  String patientAddress = "Loading address...";

  Future<void> _getAddress(double lat, double lng) async {

  final url =
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=AIzaSyBEn7X8fuoi_O5kRqEH_Hacbf_oCmBYiNw";

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {

    final data = jsonDecode(response.body);

    if (data["results"].isNotEmpty) {

      setState(() {
        patientAddress =
            data["results"][0]["formatted_address"];
      });

    }

  }
}

@override
void initState() {
  super.initState();

  final data = widget.emergencyData;
  final location = data["patientLocation"] ?? {};
  final coords = location["coordinates"];

  if (coords != null) {
    _getAddress(coords[1], coords[0]);
  }
}
  
  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {

    final data = widget.emergencyData;
    final location = data["patientLocation"] ?? {};
   
    final hospital = data["hospitalId"];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFD32F2F),
        centerTitle: true,
        title: const Text(
          "Active Case",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

           

            /* ===== PATIENT INFO ===== */

            _infoCard(
              "Patient Name",
              data["patientName"] ?? "Unknown",
              Icons.person,
            ),

            const SizedBox(height: 15),

            _infoCard(
              "Emergency Type",
              data["emergencyType"] ?? "Unknown",
              Icons.warning,
            ),

            const SizedBox(height: 15),

_infoCard(
  "Patient Location",
  patientAddress,
  Icons.location_on,
),

const SizedBox(height: 15),

if (hospital != null)
  _infoCard(
    "Assigned Hospital",
    hospital["hospitalName"] ?? "Unknown",
    Icons.local_hospital,
  ),

const SizedBox(height: 30),

            


            /* ===== BUTTON FLOW ===== */

_primaryButton(
  "Navigate",
  () {

    final patientCoords = data["patientLocation"]["coordinates"];
    final hospital = data["hospitalId"];

    // 🚑 Safety check
    if (hospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hospital data unavailable")),
      );
      return;
    }

    final hospitalCoords = hospital["location"]["coordinates"];

    double patientLng = patientCoords[0];
    double patientLat = patientCoords[1];

    double hospitalLng = hospitalCoords[0];
    double hospitalLat = hospitalCoords[1];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AmbulanceMapPage(
          patientLat: patientLat,
          patientLng: patientLng,
          hospitalLat: hospitalLat,
          hospitalLng: hospitalLng,
          ambulanceId: widget.ambulanceId,
        ),
      ),
    );

  },
),

            
          ],
        ),
      ),
    );
  }

  /* ================= BUTTON ================= */

  Widget _primaryButton(String title, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /* ================= INFO CARD ================= */

  Widget _infoCard(
      String title,
      String value,
      IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: const Color(0xFFD32F2F)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset:
              const Offset(0, 6),
        )
      ],
    );
  }
}