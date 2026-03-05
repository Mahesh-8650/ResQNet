import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CitizenMapPage extends StatefulWidget {

  final double citizenLat;
  final double citizenLng;

  final double hospitalLat;
  final double hospitalLng;

  final double ambulanceLat;
  final double ambulanceLng;

  const CitizenMapPage({
    super.key,
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

  final Set<Marker> markers = {};
  LatLng? ambulanceLocation;

  @override
void initState() {
  super.initState();

  ambulanceLocation = LatLng(
    widget.ambulanceLat,
    widget.ambulanceLng,
  );

  _loadMarkers();
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Ambulance Tracking"),
        backgroundColor: Colors.red,
      ),

      body: GoogleMap(

        initialCameraPosition: CameraPosition(
          target: LatLng(widget.citizenLat, widget.citizenLng),
          zoom: 14,
        ),

        markers: markers,

        myLocationEnabled: true,
        myLocationButtonEnabled: true,

        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }
}