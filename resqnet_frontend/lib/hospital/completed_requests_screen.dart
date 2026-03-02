import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CompletedRequestsScreen extends StatefulWidget {
  final String hospitalId;

  const CompletedRequestsScreen({
    super.key,
    required this.hospitalId,
  });

  @override
  State<CompletedRequestsScreen> createState() =>
      _CompletedRequestsScreenState();
}

class _CompletedRequestsScreenState
    extends State<CompletedRequestsScreen> {

  final String baseUrl = "https://resqnet-backend-1xe3.onrender.com";

  bool isLoading = true;

  List completedRequests = [];
  List filteredRequests = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCompleted();
  }

  // ✅ Convert UTC to Indian Time
 String formatToIndianTime(String? utcTime) {
  if (utcTime == null) return "N/A";

  DateTime utcDate = DateTime.parse(utcTime);
  DateTime istDate = utcDate.toLocal();

  return "${istDate.day}/${istDate.month}/${istDate.year} "
         "${istDate.hour}:${istDate.minute.toString().padLeft(2, '0')}";
}

  Future<void> fetchCompleted() async {
    try {
      final response = await http.get(
        Uri.parse(
            "$baseUrl/api/auth/hospital/${widget.hospitalId}/completed"),
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);

        // ✅ Sort latest first
        data.sort((a, b) {
          DateTime dateA = DateTime.parse(a["updatedAt"]);
          DateTime dateB = DateTime.parse(b["updatedAt"]);
          return dateB.compareTo(dateA);
        });

        setState(() {
          completedRequests = data;
          filteredRequests = data;
          isLoading = false;
        });
      }
    } catch (e) {
      setState((){
        isLoading = false;
      });
    }
  }

  // ✅ Search Filter
  void filterCases(String query) {
    setState(() {
      filteredRequests = completedRequests.where((req) {
        return (req["patientName"] ?? "")
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Completed Cases"),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : completedRequests.isEmpty
              ? const Center(
                  child: Text(
                    "No Completed Cases",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Column(
                  children: [

                    // ✅ Total Count
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        "Total Completed Cases: ${filteredRequests.length}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // ✅ Search Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Search Patient...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: filterCases,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ List
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {

                          final req = filteredRequests[index];
                          final ambulance = req["ambulanceId"];

                          return Card(
                            elevation: 6,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                // Status Strip
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8),
                                  decoration:
                                      const BoxDecoration(
                                    color: Colors.green,
                                    borderRadius:
                                        BorderRadius.only(
                                      topLeft:
                                          Radius.circular(18),
                                      topRight:
                                          Radius.circular(18),
                                    ),
                                  ),
                                  child: const Text(
                                    "Completed",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding:
                                      const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [

                                      Text(
                                        req["patientName"] ?? "",
                                        style:
                                            const TextStyle(
                                          fontSize: 20,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      Text(
                                          "Emergency: ${req["emergencyType"] ?? ""}"),

                                      const SizedBox(height: 6),

                                      Text(
                                          "Ambulance: ${ambulance?["fullName"] ?? ""}"),

                                      Text(
                                          "Vehicle: ${ambulance?["vehicleNumber"] ?? ""}"),

                                      Text(
                                          "Phone: ${ambulance?["phone"] ?? ""}"),

                                      const SizedBox(height: 10),

                                      Text(
                                        "Completed At: ${formatToIndianTime(req["updatedAt"])}",
                                        style:
                                            const TextStyle(
                                          fontSize: 12,
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}