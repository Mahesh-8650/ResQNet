import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class CitizenMapPage extends StatefulWidget {

    
  final String phone;
  final double citizenLat;
  final double citizenLng;

  final double hospitalLat;
  final double hospitalLng;

  final double ambulanceLat;
  final double ambulanceLng;


  const CitizenMapPage({
    super.key,
    required this.phone,
    required this.citizenLat,
    required this.citizenLng,
    required this.hospitalLat,
    required this.hospitalLng,
    required this.ambulanceLat,
    required this.ambulanceLng,
  });

  @override
  State<CitizenMapPage> createState() => _CitizenMapPageState();
}

class _CitizenMapPageState extends State<CitizenMapPage> {

  late GoogleMapController mapController;

  Timer? _refreshTimer;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  LatLng? ambulanceLocation;
  LatLng? previousLocation;
Timer? _movementTimer;
bool cameraInitialized = false;

  String etaText = "";
  String apiStatus = "";
  @override
void initState() {
  super.initState();

  ambulanceLocation = LatLng(
    widget.ambulanceLat,
    widget.ambulanceLng,
  );
  
  _loadMarkers();

  _refreshTimer = Timer.periodic(
  const Duration(seconds: 5),
  (_) {
    _fetchAmbulanceLocation();
  },
);
}

  void _loadMarkers() {

    markers.add(
      Marker(
        markerId: const MarkerId("citizen"),
        position: LatLng(widget.citizenLat, widget.citizenLng),
        infoWindow: const InfoWindow(
          title: "Your Location",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId("hospital"),
        position: LatLng(widget.hospitalLat, widget.hospitalLng),
        infoWindow: const InfoWindow(
          title: "Selected Hospital",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
    );
    if (ambulanceLocation != null) {
  markers.add(
    Marker(
      markerId: const MarkerId("ambulance"),
      position: ambulanceLocation!,
      infoWindow: const InfoWindow(
        title: "Ambulance",
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      ),
    ),
  );
}
  }

 Future<void> _fetchAmbulanceLocation() async {

  final response = await http.get(
    Uri.parse(
      "https://resqnet-backend-1xe3.onrender.com/api/citizen-emergency/status/${widget.phone}"
    ),
  );

  if (response.statusCode == 200) {

    final data = jsonDecode(response.body);

    if (data["ambulance"]?["currentLocation"]?["coordinates"] != null) {

      double lng =
          data["ambulance"]["currentLocation"]["coordinates"][0];

      double lat =
          data["ambulance"]["currentLocation"]["coordinates"][1];

      _animateAmbulance(LatLng(lat, lng));

      _drawRoute();
    }
  }
}

void _animateAmbulance(LatLng newLocation) {

  if (ambulanceLocation == null) {
    ambulanceLocation = newLocation;
    return;
  }

  previousLocation = ambulanceLocation;

  const int steps = 20;
  int currentStep = 0;

  _movementTimer?.cancel();

  _movementTimer = Timer.periodic(
    const Duration(milliseconds: 200),
    (timer) {

      currentStep++;

      double lat = previousLocation!.latitude +
          (newLocation.latitude - previousLocation!.latitude) *
              (currentStep / steps);

      double lng = previousLocation!.longitude +
          (newLocation.longitude - previousLocation!.longitude) *
              (currentStep / steps);

      setState(() {

        ambulanceLocation = LatLng(lat, lng);

        markers.clear();
        _loadMarkers();

      });

     if (!cameraInitialized) {
  mapController.animateCamera(
    CameraUpdate.newLatLng(ambulanceLocation!),
  );
  cameraInitialized = true;
}

      if (currentStep >= steps) {
        timer.cancel();
      }

    },
  );
}

  Future<void> _drawRoute() async {

  final String apiKey = "AIzaSyBEn7X8fuoi_O5kRqEH_Hacbf_oCmBYiNw";

  final String url =
      "https://maps.googleapis.com/maps/api/directions/json?"
      "origin=${ambulanceLocation!.latitude},${ambulanceLocation!.longitude}"
      "&destination=${widget.citizenLat},${widget.citizenLng}"
      "&key=$apiKey";

  final response = await http.get(Uri.parse(url));

  print("Directions API response: ${response.body}");

  if (response.statusCode == 200) {

    final data = jsonDecode(response.body);

    setState(() {
  apiStatus = data["status"].toString();
});

    if (data["routes"].isNotEmpty) {

      final points =
          data["routes"][0]["overview_polyline"]["points"];

      
      List<LatLng> routeCoords = _decodePolyline(points);

      final duration =
          data["routes"][0]["legs"][0]["duration"]["text"];


      setState(() {
  polylines.clear();

  polylines.add(
    Polyline(
      polylineId: const PolylineId("route"),
      points: routeCoords,
      color: Colors.blue,
      width: 5,
    ),
  );

  etaText = duration;
});

      

    }
  }
}

List<LatLng> _decodePolyline(String encoded) {
  List<LatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;

    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);

    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;

    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);

    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    poly.add(LatLng(lat / 1E5, lng / 1E5));
  }

  return poly;
}

@override
void dispose() {
  _refreshTimer?.cancel();
  _movementTimer?.cancel();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Ambulance Tracking"),
        backgroundColor: Colors.red,
      ),

      body: Stack(
  children: [

    GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.citizenLat, widget.citizenLng),
        zoom: 14,
      ),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) {
        mapController = controller;
        _drawRoute();
      },
    ),


    if (etaText.isNotEmpty)
      Positioned(
        top: 20,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                "Ambulance arriving in $etaText",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

  ],
),
    );
  }
}