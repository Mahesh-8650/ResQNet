import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class IncomingRequestsScreen extends StatefulWidget {
  final String hospitalId;

  const IncomingRequestsScreen({
    super.key,
    required this.hospitalId,
  });

  @override
  State<IncomingRequestsScreen> createState() =>
      _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState
    extends State<IncomingRequestsScreen> {

  final String baseUrl = "https://resqnet-backend-1xe3.onrender.com";

  bool isLoading = true;
  List requests = [];
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchRequests();

    refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (timer) {
      fetchRequests();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRequests() async {
    try {
      final response = await http.get(
        Uri.parse(
            "$baseUrl/api/auth/hospital/${widget.hospitalId}/requests"),
      );

      if (response.statusCode == 200) {
        setState(() {
          requests = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  Future<void> markAsArrived(String requestId) async {
    try {
      final response = await http.put(
        Uri.parse(
            "$baseUrl/api/auth/hospital/request/$requestId/complete"),
      );

      if (response.statusCode == 200) {
        fetchRequests();
      }
    } catch (e) {
      print("Update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Incoming Requests"),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(
                  child: Text(
                    "No Incoming Requests",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {

                    final req = requests[index];
                    final ambulance = req["ambulanceId"];

                    final double distance =
                        (req["distanceKm"] ?? 0).toDouble();

                    final eta = req["etaMinutes"];

                    return Dismissible(
                      key: ValueKey(req["_id"].toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return true;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      onDismissed: (_) =>
                          markAsArrived(req["_id"]),

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: distance < 1
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.08),
                              blurRadius: distance < 1 ? 20 : 12,
                              spreadRadius: distance < 1 ? 2 : 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            // 🔴 Emergency Strip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD32F2F),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    req["emergencyType"] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    "On The Way",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    req["patientName"] ?? "",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ambulance?["fullName"] ?? "",
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(Icons.local_shipping, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ambulance?["vehicleNumber"] ?? "",
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        ambulance?["phone"] ?? "",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      const Icon(Icons.route,
                                          size: 18, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Distance: ${distance.toStringAsFixed(2)} km",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(Icons.timer,
                                          size: 18, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Text(
                                        eta == null
                                            ? "ETA: Calculating..."
                                            : "ETA: $eta minutes",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFD32F2F),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () =>
                                          markAsArrived(req["_id"]),
                                      child: const Text(
                                        "Patient Arrived",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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