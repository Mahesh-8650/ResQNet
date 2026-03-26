import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'active_case_screen.dart';
import 'case_history_page.dart';
import 'ambulance_settings_page.dart';
import 'ambulance_performance_page.dart';

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
bool isLocationDialogOpen = false;
DateTime? lastDialogTime;
bool isUpdatingDuty = false;

int _selectedIndex = 2;

Map<String, dynamic>? activeEmergency;
bool _isOfferDialogShowing = false;
bool isAccepting = false;

final String baseUrl =
"https://resqnet-backend-1xe3.onrender.com";

Timer? _refreshTimer;
Timer? _gpsMonitorTimer;
Timer? _timeUpdateTimer;
StreamSubscription<Position>? _positionStream;

void _showGpsDialog() {
  if (isLocationDialogOpen) return;

  isLocationDialogOpen = true;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "Enable Location",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Location must be ON while you are on duty.",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    isLocationDialogOpen = false;

                    await Geolocator.openLocationSettings();
                  },
                  child: const Text("Turn ON"),
                ),
              ],
            ),
          ),

          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                isLocationDialogOpen = false;
              },
              child: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  );
}
@override
void initState() {
  super.initState();

  isAvailable = widget.isAvailable;
  isBusy = widget.isBusy;

  _startAutoRefresh();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _fetchAmbulanceStatus();

    bool enabled = await Geolocator.isLocationServiceEnabled();

    if (isAvailable && !enabled) {
      _showGpsDialog();
    }

    if (isAvailable) {
      await _startTracking();
    }
  });
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
Timer.periodic(const Duration(seconds: 3), (timer) {
if (!isAccepting) {
  _fetchAmbulanceStatus();
  _checkForAssignedEmergency();
}
});
}

/* ================= FETCH STATUS ================= */

Future<void> _fetchAmbulanceStatus() async {

if (isUpdatingDuty) return;

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

  isUpdatingDuty = true;

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
      await _startTracking();
    } else {
      _stopTracking();
    }

  } catch (_) {
    setState(() {
      isAvailable = !value;
    });
  }

  Future.delayed(const Duration(seconds: 2), () {
    isUpdatingDuty = false;
  });
}

/* ================= TRACKING ================= */

Future<void> _startTracking() async {
  bool enabled = await Geolocator.isLocationServiceEnabled();

  _startGpsMonitor(); // always start monitor

  if (!enabled) return; // ❌ DO NOT start location stream

  await _startLocationStream();
  _startTimeBasedUpdates();
}

void _stopTracking() {
_positionStream?.cancel();
_gpsMonitorTimer?.cancel();
_timeUpdateTimer?.cancel();
}

Future<void> _startLocationStream() async {
LocationPermission permission =
    await Geolocator.checkPermission();

if (permission == LocationPermission.denied ||
    permission == LocationPermission.deniedForever) {
  return; // ❌ do nothing (NO popup)
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
    sendLocationToBackend(  
        position.latitude,  
        position.longitude);  
  }  
});

}

void _startTimeBasedUpdates() {
_timeUpdateTimer =
Timer.periodic(const Duration(seconds: 5), (timer) async {
if (!isAvailable || !isGpsActive) return;

try {  
Position? position = await Geolocator.getLastKnownPosition();

if (position != null) {
  sendLocationToBackend(position.latitude, position.longitude);
}   
  } catch (_) {}  
});

}

void _startGpsMonitor() {
  _gpsMonitorTimer =
      Timer.periodic(const Duration(seconds: 3), (_) async {

    if (!mounted) return;

    bool enabled = await Geolocator.isLocationServiceEnabled();

    // ❌ GPS OFF → show your dialog
    if (!enabled && isAvailable) {
      _showGpsDialog();
    }

    // ✅ GPS ON → close dialog + start tracking if not started
    if (enabled) {

      if (isLocationDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        isLocationDialogOpen = false;
      }

      // 🔥 AUTO START TRACKING (important)
      if (isAvailable && _positionStream == null) {
        await _startLocationStream();
        _startTimeBasedUpdates();
      }
    }

    setState(() {
      isGpsActive = enabled;
    });
  });
}
/* ================= EMERGENCY CHECK ================= */

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

  // Close dialog if open  
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
if (status == "offered") {

  if (_isOfferDialogShowing || isAccepting) return;

  _isOfferDialogShowing = true;

  showOfferDialog(emergency);

  return;
}
// ASSIGNED  
if (status == "assigned") {  
  if (activeEmergency == null ||  
      activeEmergency!["_id"] != emergency["_id"]) {  

    setState(() {  
      activeEmergency = emergency;  
      isBusy = true;  
      isAvailable = true;  
    });  
  }  
}

} catch (_) {}
}

/* ================= OFFER DIALOG ================= */

void showOfferDialog(Map<String, dynamic> emergency) {
showDialog(
context: context,
barrierDismissible: false,
builder: (context) => AlertDialog(
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
  _respondToEmergency(emergency["_id"]);
Navigator.of(context, rootNavigator: true).pop();
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

  if (isAccepting) return;
  isAccepting = true;
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
isAccepting = false;
}

/* ================= LOCATION SEND ================= */

Future<void> sendLocationToBackend(
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
} catch (e) {}
}

/* ================= ACTIVE CASE ================= */

Future<void> _openActiveCase() async {

await _checkForAssignedEmergency(); // Ensure we have the latest emergency data

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

Widget _buildHomePage() {
return Container(
width: double.infinity,
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
child: SingleChildScrollView(
child: Column(
children: [

const SizedBox(height: 30),  

        /// HEADER  
        Padding(  
          padding: const EdgeInsets.symmetric(horizontal: 20),  
          child: Column(  
            crossAxisAlignment: CrossAxisAlignment.start,  
            children: [  

              const Text(  
                "Ambulance Dashboard 🚑",  
                style: TextStyle(  
                  fontSize: 20,  
                  fontWeight: FontWeight.bold,  
                ),  
              ),  

              const SizedBox(height: 4),  

              Row(  
                children: [  
                  const Icon(Icons.local_shipping, size: 16),  
                  const SizedBox(width: 4),  
                  Text("Vehicle ID: ${widget.vehicleNumber}"),  
                ],  
              ),  
            ],  
          ),  
        ),  

        const SizedBox(height: 15),  

        /// DUTY CONTROL  
        Container(  
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),  
          padding: const EdgeInsets.all(14),  
          decoration: _cardDecoration(),  
          child: Row(  
            mainAxisAlignment: MainAxisAlignment.spaceBetween,  
            children: [  

              Text(  
                isAvailable ? "ON DUTY" : "OFF DUTY",  
                style: TextStyle(  
                  fontSize: 16,  
                  fontWeight: FontWeight.bold,  
                  color: isAvailable ? Colors.green : Colors.red,  
                ),  
              ),  

              Switch(  
                value: isAvailable,  
                activeColor: Colors.green,  
                onChanged: _updateDuty,  
              ),  
            ],  
          ),  
        ),  

        const SizedBox(height: 12),  

        /// STATUS  
        const Padding(  
          padding: EdgeInsets.symmetric(horizontal: 20),  
          child: Align(  
            alignment: Alignment.centerLeft,  
            child: Text(  
              "Ambulance Status",  
              style: TextStyle(  
                fontWeight: FontWeight.bold,  
                fontSize: 15,  
              ),  
            ),  
          ),  
        ),  

        const SizedBox(height: 8),  

        Container(  
          margin: const EdgeInsets.symmetric(horizontal: 20),  
          padding: const EdgeInsets.all(12),  
          decoration: _cardDecoration(),  
          child: Row(  
            children: [  
              Icon(Icons.check_circle, color: statusColor),  
              const SizedBox(width: 8),  
              Text("Status: $statusText"),  
            ],  
          ),  
        ),  

        const SizedBox(height: 20),  

        /// CASE HISTORY  
        _bigCard(  
          "Case History",  
          "Check completed emergency cases",  
          Icons.history,  
          Colors.orange,  
          () {  
            setState(() {  
              _selectedIndex = 0;  
            });  
          },  
        ),  

        /// PERFORMANCE  
        _bigCard(  
          "Performance",  
          "View ambulance performance",  
          Icons.bar_chart,  
          Colors.blue,  
          () {  
            setState(() {  
              _selectedIndex = 3;  
            });  
          },  
        ),  

        const SizedBox(height: 12),  

        /// QUICK ACTIONS  
        const Padding(  
          padding: EdgeInsets.symmetric(horizontal: 20),  
          child: Align(  
            alignment: Alignment.centerLeft,  
            child: Text(  
              "Quick Actions",  
              style: TextStyle(  
                fontWeight: FontWeight.bold,  
                fontSize: 15,  
              ),  
            ),  
          ),  
        ),  

        const SizedBox(height: 10),  

        Row(  
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,  
          children: [  

            _smallCard(  
              Icons.local_hospital,  
              "Active Case",  
              "Open current emergency case",  
              Colors.red,  
              _openActiveCase,  
            ),  

            _smallCard(  
              Icons.settings,  
              "Settings",  
              "Manage app preferences",  
              Colors.blueGrey,  
              () {  
                setState(() {  
                  _selectedIndex = 4;  
                });  
              },  
            ),  
          ],  
        ),  

        const SizedBox(height: 30),  

      ],  
    ),  
  ),  
),

);
}
/* ================= UI ================= */

@override
Widget build(BuildContext context) {

return Scaffold(
backgroundColor: const Color(0xFF9EA6AA),

body: _selectedIndex == 2  
? _buildHomePage()  
: _selectedIndex == 0  
    ? CaseHistoryPage(ambulanceId: widget.ambulanceId)  
    : _selectedIndex == 3  
        ? AmbulancePerformancePage(  
            ambulanceId: widget.ambulanceId,  
          )  
        : _selectedIndex == 4  
            ? AmbulanceSettingsPage(  
                ambulanceId: widget.ambulanceId,  
              )  
            : const SizedBox(),  

bottomNavigationBar: BottomNavigationBar(  
  type: BottomNavigationBarType.fixed,  
  currentIndex: _selectedIndex,  
  selectedItemColor: Colors.red,  
  unselectedItemColor: Colors.grey,  
  showUnselectedLabels: true,  

  onTap: (index) async {  

    if (index == 1) {  
      await _openActiveCase();  
      return;  
    }  

    setState(() {  
      _selectedIndex = index;  
    });  

  },  

  items: const [

BottomNavigationBarItem(
icon: Icon(Icons.history),
label: "History",
),

BottomNavigationBarItem(
icon: Icon(Icons.local_hospital),
label: "Active",
),

BottomNavigationBarItem(
icon: Icon(Icons.home, size: 30),
label: "Home",
),

BottomNavigationBarItem(
icon: Icon(Icons.bar_chart),
label: "Performance",
),

BottomNavigationBarItem(
icon: Icon(Icons.settings),
label: "Settings",
),

],
),
);
}

Widget _bigCard(
String title,
String subtitle,
IconData icon,
Color color,
VoidCallback onTap,
) {
return GestureDetector(
onTap: onTap,
child: Container(
margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
padding: const EdgeInsets.all(14),
decoration: _cardDecoration(),
child: Row(
children: [

Expanded(  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  

            Text(  
              title,  
              style: const TextStyle(  
                  fontSize: 16,  
                  fontWeight: FontWeight.bold),  
            ),  

            const SizedBox(height: 4),  

            Text(  
              subtitle,  
              style: const TextStyle(fontSize: 12),  
            ),  

          ],  
        ),  
      ),  

      Icon(icon, size: 28, color: color),  

    ],  
  ),  
),

);
}

Widget _smallCard(
IconData icon,
String title,
String subtitle,
Color color,
VoidCallback onTap,
) {
return GestureDetector(
onTap: onTap,
child: Container(
width: 140,
height: 120,
padding: const EdgeInsets.all(12),
decoration: _cardDecoration(),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [

Icon(icon, size: 32, color: color),  

      const SizedBox(height: 8),  

      Text(  
        title,  
        style: const TextStyle(  
          fontWeight: FontWeight.bold,  
        ),  
      ),  

      const SizedBox(height: 4),  

      Text(  
        subtitle,  
        textAlign: TextAlign.center,  
        style: const TextStyle(  
          fontSize: 11,  
          color: Colors.grey,  
        ),  
      ),  
    ],  
  ),  
),

);
}

BoxDecoration _cardDecoration() {
return BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
blurRadius: 12,
offset: const Offset(0, 6),
)
],
);
}
}