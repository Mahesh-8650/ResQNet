import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'active_case_screen.dart';
import 'case_history_page.dart';

class AmbulanceHomeScreen extends StatefulWidget {
  final String ambulanceId;
  final String ambulanceName;
  final String vehicleNumber;
  final bool isAvailable;
  final bool isBusy;

  const AmbulanceHomeScreen({
    super.key,
    required this.ambulanceId,
    required this.ambulanceName,
    required this.vehicleNumber,
    required this.isAvailable,
    required this.isBusy,
  });

  @override
  State<AmbulanceHomeScreen> createState() =>
      _AmbulanceHomeScreenState();
}

class _AmbulanceHomeScreenState
    extends State<AmbulanceHomeScreen> {

  late bool isAvailable;
  late bool isBusy;
  bool isGpsActive = true;

  Map<String, dynamic>? activeEmergency;
  bool _isOfferDialogShowing = false;

  final String baseUrl =
      "https://resqnet-backend-1xe3.onrender.com";

  Timer? _refreshTimer;
  Timer? _gpsMonitorTimer;
  Timer? _timeUpdateTimer;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();

    isAvailable = widget.isAvailable;
    isBusy = widget.isBusy;

    _startAutoRefresh();

    if (isAvailable) {
      _startTracking();
    }
  }

  /* ================= STATUS ================= */

  String get statusText {
    if (isBusy) return "BUSY";
    if (isAvailable) return "ON DUTY";
    return "OFF DUTY";
  }

  Color get statusColor {
    if (isBusy) return Colors.orange;
    if (isAvailable) return Colors.green;
    return Colors.red;
  }

  /* ================= AUTO REFRESH ================= */

  void _startAutoRefresh() {
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchAmbulanceStatus();
      _checkForAssignedEmergency();
    });
  }

  /* ================= FETCH STATUS ================= */

  Future<void> _fetchAmbulanceStatus() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/auth/ambulance/${widget.ambulanceId}"),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        isAvailable = data["isAvailable"] ?? isAvailable;
        isBusy = data["isBusy"] ?? isBusy;
      });

    } catch (_) {}
  }

  /* ================= DUTY UPDATE ================= */

  Future<void> _updateDuty(bool value) async {

    if (isBusy && value == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You have an active patient. Complete the case first.",
          ),
        ),
      );
      return;
    }

    // 🔥 Update immediately
    setState(() {
      isAvailable = value;
    });

    try {
      await http.put(
        Uri.parse("$baseUrl/api/auth/update-duty/${widget.ambulanceId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isAvailable": value}),
      );

      if (value) {
        _startTracking();
      } else {
        _stopTracking();
      }

    } catch (_) {
      // rollback if failed
      setState(() {
        isAvailable = !value;
      });
    }
  }

  /* ================= TRACKING ================= */

  Future<void> _startTracking() async {
    await _startLocationStream();
    _startGpsMonitor();
    _startTimeBasedUpdates();
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _gpsMonitorTimer?.cancel();
    _timeUpdateTimer?.cancel();
  }

  Future<void> _startLocationStream() async {
    LocationPermission permission =
        await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    _positionStream?.cancel();

    _positionStream =
        Geolocator.getPositionStream(
                locationSettings: locationSettings)
            .listen((position) {
      if (isGpsActive) {
        _sendLocationToBackend(
            position.latitude,
            position.longitude);
      }
    });
  }

  void _startTimeBasedUpdates() {
    _timeUpdateTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!isAvailable || !isGpsActive) return;

      try {
        Position position =
            await Geolocator.getCurrentPosition(
          desiredAccuracy:
              LocationAccuracy.bestForNavigation,
        );

        _sendLocationToBackend(
            position.latitude,
            position.longitude);
      } catch (_) {}
    });
  }

  void _startGpsMonitor() {
    _gpsMonitorTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      bool enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      setState(() {
        isGpsActive = enabled;
      });
    });
  }

  /* ================= EMERGENCY CHECK ================= */

  Future<void> _checkForAssignedEmergency() async {

    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/citizen-emergency/ambulance/${widget.ambulanceId}",
        ),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      if (!data["hasEmergency"]) {

  // 🔥 If dialog is open, close it
  if (_isOfferDialogShowing) {
    Navigator.of(context, rootNavigator: true).pop();
    _isOfferDialogShowing = false;
  }

  if (activeEmergency != null) {
    setState(() {
      activeEmergency = null;
      isBusy = false;
    });
  }

  return;
}

      final emergency = data["emergency"];
      final status = emergency["status"];

      // OFFER
      if (status == "offered" &&
          !_isOfferDialogShowing) {
        _isOfferDialogShowing = true;
        _showOfferDialog(emergency);
        return;
      }

      // ASSIGNED
      if (status == "assigned") {
        if (activeEmergency == null ||
            activeEmergency!["_id"] != emergency["_id"]) {
          setState(() {
            activeEmergency = emergency;
            isBusy = true;
            isAvailable=true;
          });
        }
      }

    } catch (_) {}
  }

  /* ================= OFFER DIALOG ================= */

 void _showOfferDialog(Map<String, dynamic> emergency) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("🚑 New Emergency"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Patient: ${emergency["patientName"] ?? "Unknown"}"),
          const SizedBox(height: 6),
          Text("Type: ${emergency["emergencyType"] ?? "Unknown"}"),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _respondToEmergency(emergency["_id"]);
          },
          child: const Text("Accept"),
        ),
      ],
    ),
  ).then((_) {
    _isOfferDialogShowing = false;
  });
}

  Future<void> _respondToEmergency(String id) async {
  try {
    final response = await http.put(
      Uri.parse("$baseUrl/api/citizen-emergency/respond/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ambulanceId": widget.ambulanceId
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        isBusy = true;
        isAvailable = true;   // Stay ON DUTY
        activeEmergency = data["emergency"];
      });

      _isOfferDialogShowing = false; // 🔥 Prevent repeat
    }
  } catch (e) {
    print("Respond error: $e");
  }
}

  /* ================= LOCATION SEND ================= */

  Future<void> _sendLocationToBackend(
      double lat, double lng) async {
    try {
      await http.put(
        Uri.parse(
            "$baseUrl/api/auth/update-location/${widget.ambulanceId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "latitude": lat,
          "longitude": lng,
        }),
      );
    } catch (_) {}
  }

  /* ================= ACTIVE CASE ================= */

  Future<void> _openActiveCase() async {

    await _checkForAssignedEmergency();

    if (activeEmergency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No active emergency."),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveCaseScreen(
          emergencyId: activeEmergency!["_id"],
          emergencyData: activeEmergency!,
          ambulanceId: widget.ambulanceId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _stopTracking();
    super.dispose();
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        centerTitle: true,
        title: const Text(
          "Ambulance Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildWelcomeCard(),
            const SizedBox(height: 25),

            const Text("Duty Control",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildDutyCard(),

            const SizedBox(height: 25),

            const Text("Quick Actions",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 15),

            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome, ${widget.ambulanceName}",
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("Vehicle: ${widget.vehicleNumber}",
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(isAvailable ? "ON DUTY" : "OFF DUTY",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isAvailable
                      ? Colors.green
                      : Colors.red)),
          Switch(
            value: isAvailable,
            activeColor: Colors.green,
            onChanged: _updateDuty,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      physics:
          const NeverScrollableScrollPhysics(),
      children: [
        _actionCard(
  Icons.history,
  "Case History",
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseHistoryPage(
          ambulanceId: widget.ambulanceId,
        ),
      ),
    );
  },
),
        _actionCard(Icons.local_hospital, "Active Case",
            onTap: _openActiveCase),
        _actionCard(Icons.bar_chart, "Performance"),
        _actionCard(Icons.settings, "Settings"),
      ],
    );
  }

  Widget _actionCard(
      IconData icon,
      String title,
      {VoidCallback? onTap}) {
    return Container(
      decoration: _cardDecoration(),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 26,
                  color: const Color(0xFFD32F2F)),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight:
                        FontWeight.w500)),
          ],
        ),
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