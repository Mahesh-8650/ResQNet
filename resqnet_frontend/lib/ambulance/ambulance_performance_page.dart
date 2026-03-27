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
      "https://resqnet-oe5z.onrender.com";

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
  IconData icon,
  String title,
  String value,
  Color iconColor,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4)
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
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
    child: isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  "Performance",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              buildMetricCard(
                Icons.check_circle,
                "Total Completed Cases",
                totalCompleted.toString(),
                Colors.red,
              ),

              buildMetricCard(
                Icons.calendar_month,
                "Monthly Completed Cases",
                monthlyCompleted.toString(),
                Colors.orange,
              ),

              buildMetricCard(
                Icons.timer,
                "Average Response Time",
                "${avgResponseTime.toStringAsFixed(1)} sec",
                Colors.red,
              ),

              buildMetricCard(
                Icons.route,
                "Total Distance Covered",
                "${totalDistance.toStringAsFixed(1)} km",
                Colors.blue,
              ),

              _acceptanceCard(),

              const SizedBox(height: 10),
            ],
          ),
  ),
),
    );
  }
  Widget _acceptanceCard() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4)
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Acceptance Rate",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 12),

LinearProgressIndicator(
  value: (acceptanceRate.clamp(0, 100)) / 100,
  backgroundColor: Colors.grey.shade300,
  color: Colors.green,
  minHeight: 10,
),
        const SizedBox(height: 8),

        Text(
          "${acceptanceRate.toStringAsFixed(1)} %",
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    ),
  );
}
}