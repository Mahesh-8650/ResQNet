import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AmbulanceMapPage extends StatefulWidget {
  final double patientLat;
  final double patientLng;
  final double hospitalLat;
  final double hospitalLng;
  final String ambulanceId;

  const AmbulanceMapPage({
    super.key,
    required this.patientLat,
    required this.patientLng,
    required this.hospitalLat,
    required this.hospitalLng,
    required this.ambulanceId,
  });

  @override
  State<AmbulanceMapPage> createState() => _AmbulanceMapPageState();
}

class _AmbulanceMapPageState extends State<AmbulanceMapPage> {
  late GoogleMapController mapController;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  LatLng? ambulanceLocation;
  LatLng? previousLocation;
  BitmapDescriptor? ambulanceIcon;
  double ambulanceBearing = 0;
  double lastCameraBearing = 0;

  Timer? locationTimer;

  bool reachedPatient = false;
  bool mapReady = false;
  bool userMovedMap = false;
  bool tripCompleted = false;

  String emergencyId = "";

  String etaText = "";
  String distanceText = "";
  String nextInstruction = "";
  IconData navigationIcon = Icons.arrow_upward;

  final FlutterTts flutterTts = FlutterTts();
  String lastSpokenInstruction = "";

  final String apiKey = "AIzaSyBEn7X8fuoi_O5kRqEH_Hacbf_oCmBYiNw";

  Future<void> _getDriverLocation() async {

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  previousLocation = ambulanceLocation;

  ambulanceLocation = LatLng(
    position.latitude,
    position.longitude,
  );
}
 

  @override
  void initState() {
    super.initState();

    _fetchDriverLocation();

    locationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchDriverLocation(),
    );
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }

  /* ================= FETCH DRIVER LOCATION ================= */
Future<void> _fetchDriverLocation() async {
  try {

    final response = await http.get(
      Uri.parse(
        "https://resqnet-backend-1xe3.onrender.com/api/citizen-emergency/ambulance/${widget.ambulanceId}",
      ),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      if (data["hasEmergency"] == true) {

        final emergency = data["emergency"];
        emergencyId = emergency["_id"];

        double patientLng =
            emergency["patientLocation"]["coordinates"][0];

        double patientLat =
            emergency["patientLocation"]["coordinates"][1];

        // simulate ambulance 5km away
        await _getDriverLocation();

        if (previousLocation != null && ambulanceLocation != null) {

 double movementDistance = _calculateDistance(
  previousLocation!.latitude,
  previousLocation!.longitude,
  ambulanceLocation!.latitude,
  ambulanceLocation!.longitude,
);

// Ignore GPS noise if movement < 5 meters
if (movementDistance > 0.005) {

  double newBearing =
      _calculateBearing(previousLocation!, ambulanceLocation!);

  double diff = (newBearing - ambulanceBearing).abs();

  if (diff > 40) {
    ambulanceBearing = ( newBearing -ambulanceBearing)* 0.3 + ambulanceBearing;
  }

}

}

        await _animateAmbulance();

        _checkPatientReached();

        _loadMarkers();

        

        if (mapReady) {
          await _drawRoute();
        }

        setState(() {});
      }
    }

  } catch (e) {
    print("Location error: $e");
  }
}
  /* ================= LOAD MARKERS ================= */

  void _loadMarkers() {
    Set<Marker> tempMarkers = {};

    if (ambulanceLocation != null) {
      tempMarkers.add(
        Marker(
          markerId: const MarkerId("ambulance"),
          position: ambulanceLocation!,
          rotation: ambulanceBearing,
anchor: const Offset(0.5, 0.5),
          icon: ambulanceIcon ?? BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: "Ambulance"),
        ),
      );
    }

    tempMarkers.add(
      Marker(
        markerId: const MarkerId("patient"),
        position: LatLng(widget.patientLat, widget.patientLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
        infoWindow: const InfoWindow(title: "Patient"),
      ),
    );

    tempMarkers.add(
      Marker(
        markerId: const MarkerId("hospital"),
        position: LatLng(widget.hospitalLat, widget.hospitalLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: const InfoWindow(title: "Hospital"),
      ),
    );

    markers = tempMarkers;
  }

  /* ================= DRAW ROUTE ================= */

Future<void> _drawRoute() async {

  if (ambulanceLocation == null) return;

  LatLng destination = reachedPatient
      ? LatLng(widget.hospitalLat, widget.hospitalLng)
      : LatLng(widget.patientLat, widget.patientLng);

  PolylinePoints polylinePoints = PolylinePoints(apiKey: apiKey);

  PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    request: PolylineRequest(
      origin: PointLatLng(
        ambulanceLocation!.latitude,
        ambulanceLocation!.longitude,
      ),
      destination: PointLatLng(
        destination.latitude,
        destination.longitude,
      ),
      mode: TravelMode.driving,
    ),
  );
  print("ROUTE STATUS: ${result.status}");
print("POINTS: ${result.points.length}");

  

  if (result.points.isEmpty) {
    print("NO ROUTE FOUND");
    return;
  }

  List<LatLng> polylineCoordinates = [];

  for (var point in result.points) {
    polylineCoordinates.add(
      LatLng(point.latitude, point.longitude),
    );
  }

  setState(() {
    polylines = {
      Polyline(
        polylineId: const PolylineId("route"),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 6,
      ),
    };
  });

  final url =
    "https://maps.googleapis.com/maps/api/directions/json?"
    "origin=${ambulanceLocation!.latitude},${ambulanceLocation!.longitude}"
    "&destination=${destination.latitude},${destination.longitude}"
    "&mode=driving"
    "&key=$apiKey";

final response = await http.get(Uri.parse(url));

final data = jsonDecode(response.body);

if (data["routes"].isNotEmpty) {
  final leg = data["routes"][0]["legs"][0];

  final step = leg["steps"][0];

String distance = step["distance"]["text"];

if (distance.contains("km")) {
  double km = double.parse(distance.replaceAll(" km", ""));

  if (km < 1) {
    int meters = (km * 1000).round();
    distance = "$meters m";
  }
}
String maneuver = step["maneuver"] ?? "straight";

String instruction = "";

if (maneuver == "turn-right") {
  instruction = "Turn right in $distance";
  navigationIcon = Icons.turn_right;
}
else if (maneuver == "turn-left") {
  instruction = "Turn left in $distance";
  navigationIcon = Icons.turn_left;
}
else if (maneuver == "uturn-left" || maneuver == "uturn-right") {
  instruction = "Make a U-turn in $distance";
  navigationIcon = Icons.u_turn_left;
}
else {
  instruction = "Continue straight for $distance";
  navigationIcon = Icons.arrow_upward;
}

nextInstruction = instruction;

if (instruction != lastSpokenInstruction) {
  lastSpokenInstruction = instruction;
  await flutterTts.speak(instruction);
}

  setState(() {
    distanceText = leg["distance"]["text"];
    etaText = leg["duration"]["text"];
  });
}
}
  /* ================= CHECK PATIENT REACHED ================= */

  void _checkPatientReached() {
    if (ambulanceLocation == null) return;

    double distance = _calculateDistance(
      ambulanceLocation!.latitude,
      ambulanceLocation!.longitude,
      widget.patientLat,
      widget.patientLng,
    );

    if (distance < 0.05) {
      reachedPatient = true;
    }
  }

  void _markPatientReached() {
  setState(() {
    reachedPatient = true;
  });

  _drawRoute();
}
Future<void> _completeEmergency() async {

  if (emergencyId == null) return;

  try {

    await http.put(
      Uri.parse(
        "https://resqnet-backend-1xe3.onrender.com/api/citizen-emergency/update-status/$emergencyId",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "status": "completed",
      }),
    );

    setState(() {
      tripCompleted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Emergency marked as completed"),
      ),
    );

  } catch (e) {
    print("Completion error: $e");
  }

}

  /* ================= DISTANCE ================= */

 double _calculateDistance(
    double lat1, double lon1, double lat2, double lon2) {

  const double R = 6371;

  double dLat = _deg2rad(lat2 - lat1);
  double dLon = _deg2rad(lon2 - lon1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) *
          cos(_deg2rad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c;
}

Future<void> _animateAmbulance() async {

  if (previousLocation == null || ambulanceLocation == null) return;

  const int steps = 20;

  double latStep =
      (ambulanceLocation!.latitude - previousLocation!.latitude) / steps;

  double lngStep =
      (ambulanceLocation!.longitude - previousLocation!.longitude) / steps;

  for (int i = 0; i < steps; i++) {

    double lat = previousLocation!.latitude + latStep * i;
    double lng = previousLocation!.longitude + lngStep * i;

    LatLng intermediate = LatLng(lat, lng);

    setState(() {
      markers.removeWhere((m) => m.markerId.value == "ambulance");

      markers.add(
        Marker(
          markerId: const MarkerId("ambulance"),
          position: intermediate,
          rotation: ambulanceBearing,
anchor: const Offset(0.5, 0.5),
          icon: ambulanceIcon ?? BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: "Ambulance"),
        ),
      );
    });
    if (mapReady && i == steps - 1 && !userMovedMap) {

  LatLng cameraTarget =
      _getPointAhead(ambulanceLocation!, ambulanceBearing);

  double diff = (ambulanceBearing - lastCameraBearing).abs();

  // Rotate camera ONLY when there is real turn
  if (diff > 30) {

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: cameraTarget,
          zoom: 18,
          bearing: ambulanceBearing,
          tilt: 60,
        ),
      ),
    );

    lastCameraBearing = ambulanceBearing;
  }

}

    await Future.delayed(const Duration(milliseconds: 100));
  }
}

double _calculateBearing(LatLng start, LatLng end) {
  double lat1 = _deg2rad(start.latitude);
  double lon1 = _deg2rad(start.longitude);
  double lat2 = _deg2rad(end.latitude);
  double lon2 = _deg2rad(end.longitude);

  double dLon = lon2 - lon1;

  double y = sin(dLon) * cos(lat2);
  double x = cos(lat1) * sin(lat2) -
      sin(lat1) * cos(lat2) * cos(dLon);

  double bearing = atan2(y, x);

  bearing = bearing * 180 / pi;
  bearing = (bearing + 360) % 360;

  return bearing;
}

double _deg2rad(double deg) {
  return deg * (pi / 180);
}

LatLng _getPointAhead(LatLng position, double bearing) {
  const double distance = 0.0005; // around 30 meters

  double rad = bearing * pi / 180;

  double newLat = position.latitude + distance * cos(rad);
  double newLng = position.longitude + distance * sin(rad);

  return LatLng(newLat, newLng);
}

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Navigation"),
        backgroundColor: Colors.red,
      ),
      body: Stack(
  children: [

    GoogleMap(
      padding: const EdgeInsets.only(top: 140 , right: 10),
      compassEnabled: true,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.patientLat, widget.patientLng),
        zoom: 17,
      ),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      onCameraMoveStarted: () {
        userMovedMap = true;
      },
      onMapCreated: (controller) {

        mapController = controller;
        mapReady = true;

        _loadMarkers();

        Future.delayed(const Duration(seconds: 1), (){
          _drawRoute();
        });

        setState(() {});
      },
    ),

    Positioned(
  top: 15,
  left: 16,
  right: 16,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: Offset(0,3),
        )
      ],
    ),
    child: Row(
      children: [

        // Navigation Icon
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            navigationIcon,
            color: Colors.green,
            size: 26,
          ),
        ),

        const SizedBox(width: 12),

        // Instruction + ETA
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                nextInstruction,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "$distanceText • $etaText",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),

            ],
          ),
        ),

      ],
    ),
  ),
),

    Positioned(
  bottom: 110,
  right: 20,
  child: FloatingActionButton(
    backgroundColor: Colors.white,
    child: const Icon(Icons.my_location, color: Colors.blue),
    onPressed: () {

      userMovedMap = false;

      if (ambulanceLocation != null) {

        LatLng cameraTarget =
            _getPointAhead(ambulanceLocation!, ambulanceBearing);

        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: cameraTarget,
              zoom: 18,
              bearing: ambulanceBearing,
              tilt: 60,
            ),
          ),
        );

      }

    },
  ),
),

    Positioned(
  bottom: 30,
  left: 80,
  right: 80,
  child: ElevatedButton(
    onPressed: tripCompleted
    ? null
    : () {

        if (!reachedPatient) {

          _markPatientReached();

        } else {

          _completeEmergency();

        }

      },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: Text(
      reachedPatient ? "COMPLETED" : "ARRIVED",
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  ),
),

  ],
)
    );
  }
}