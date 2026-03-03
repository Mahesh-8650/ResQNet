import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AmbulancePerformancePage extends StatefulWidget {
  final String ambulanceId;

  const AmbulancePerformancePage({
    super.key,
    required this.ambulanceId,
  });

  @override
  State<AmbulancePerformancePage> createState() =>
      _AmbulancePerformancePageState();
}

class _AmbulancePerformancePageState
    extends State<AmbulancePerformancePage> {

  final String baseUrl =
      "https://resqnet-backend-1xe3.onrender.com";

  bool isLoading = true;

  int totalCompleted = 0;
  int monthlyCompleted = 0;
  double avgResponseTime = 0;
  double acceptanceRate = 0;
  double totalDistance = 0;

  @override
  void initState() {
    super.initState();
    fetchPerformance();
  }

  Future<void> fetchPerformance() async {
    try {
      final response = await http.get(
        Uri.parse(
            "$baseUrl/api/performance/${widget.ambulanceId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          totalCompleted = data["totalCompleted"] ?? 0;
          monthlyCompleted = data["monthlyCompleted"] ?? 0;
          avgResponseTime =
              (data["avgResponseTime"] ?? 0).toDouble();
          acceptanceRate =
              (data["acceptanceRate"] ?? 0).toDouble();
          totalDistance =
              (data["totalDistance"] ?? 0).toDouble();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Widget buildMetricCard(
      String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.red),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Performance"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [

                  buildMetricCard(
                    "Total Completed Cases",
                    totalCompleted.toString(),
                    Icons.check_circle,
                  ),

                  const SizedBox(height: 15),

                  buildMetricCard(
                    "Monthly Completed Cases",
                    monthlyCompleted.toString(),
                    Icons.calendar_month,
                  ),

                  const SizedBox(height: 15),

                  buildMetricCard(
                    "Average Response Time",
                    "${avgResponseTime.toStringAsFixed(1)} sec",
                    Icons.timer,
                  ),

                  const SizedBox(height: 15),

                  buildMetricCard(
                    "Total Distance Covered",
                    "${totalDistance.toStringAsFixed(1)} km",
                    Icons.route,
                  ),

                  const SizedBox(height: 25),

                  Container(
                    padding:
                        const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.grey.shade300,
                          blurRadius: 6,
                          offset:
                              const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Acceptance Rate",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold),
                        ),

                        const SizedBox(height: 15),

                        LinearProgressIndicator(
                          value:
                              acceptanceRate / 100,
                          backgroundColor:
                              Colors.grey.shade300,
                          color: Colors.green,
                          minHeight: 10,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "${acceptanceRate.toStringAsFixed(1)} %",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}