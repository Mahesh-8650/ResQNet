import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';

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

  Timer? locationTimer;

  bool reachedPatient = false;
  bool mapReady = false;
  String etaText = "";
  String distanceText = "";
  String nextInstruction = "";

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

        double patientLng =
            emergency["patientLocation"]["coordinates"][0];

        double patientLat =
            emergency["patientLocation"]["coordinates"][1];

        // simulate ambulance 5km away
        await _getDriverLocation();
        await _animateAmbulance();

        _checkPatientReached();

        _loadMarkers();

        if (ambulanceLocation != null) {
  mapController.animateCamera(
    CameraUpdate.newLatLng(ambulanceLocation!),
  );
}

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
          icon: BitmapDescriptor.defaultMarkerWithHue(
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

nextInstruction = step["html_instructions"]
    .replaceAll(RegExp(r'<[^>]*>'), '');

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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: "Ambulance"),
        ),
      );
    });

    await Future.delayed(const Duration(milliseconds: 100));
  }
}

double _deg2rad(double deg) {
  return deg * (pi / 180);
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
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.patientLat, widget.patientLng),
        zoom: 14,
      ),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
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
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 5)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
  Text("Distance: $distanceText"),
  Text("ETA: $etaText"),
  const SizedBox(height: 6),
  Text(
    nextInstruction,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
],
        ),
      ),
    ),
    Positioned(
  bottom: 30,
  left: 80,
  right: 80,
  child: ElevatedButton(
    onPressed: _markPatientReached,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: const Text(
      "ARRIVED",
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
),

  ],
)
    );
  }
}