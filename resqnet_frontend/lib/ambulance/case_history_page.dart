import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CaseHistoryPage extends StatefulWidget {
  final String ambulanceId;

  const CaseHistoryPage({
    super.key,
    required this.ambulanceId,
  });

  @override
  State<CaseHistoryPage> createState() => _CaseHistoryPageState();
}

class _CaseHistoryPageState extends State<CaseHistoryPage> {

  final String baseUrl =
      "https://resqnet-backend-1xe3.onrender.com";

  final TextEditingController _searchController =
      TextEditingController();

  List<dynamic> allCases = [];
  List<dynamic> filteredCases = [];
  Map<String, String> addressMap = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

Future<void> _fetchHistory() async {
  try {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/citizen-emergency/history/${widget.ambulanceId}",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        allCases = data["history"] ?? [];
        filteredCases = allCases;
        isLoading = false;
      });

      // 🔥 Fetch address for each case
      for (var caseItem in allCases) {

        final coords = caseItem["patientLocation"]["coordinates"];

        double lng = coords[0];
        double lat = coords[1];

        _getAddress(caseItem["_id"], lat, lng);

      }

    } else {
      setState(() {
        isLoading = false;
        allCases = [];
        filteredCases = [];
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
      allCases = [];
      filteredCases = [];
    });
  }
}

Future<void> _getAddress(String id, double lat, double lng) async {

  final url =
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=AIzaSyBEn7X8fuoi_O5kRqEH_Hacbf_oCmBYiNw";

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {

    final data = jsonDecode(response.body);

    if (data["results"].isNotEmpty) {

      setState(() {
        addressMap[id] =
            data["results"][0]["formatted_address"];
      });

    }

  }
}

  void _searchPatient(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredCases = allCases;
      });
      return;
    }

    final results = allCases.where((caseItem) {
      final name =
          (caseItem["patientName"] ?? "")
              .toString()
              .toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredCases = results;
    });
  }

String _formatDate(String dateString) {
  final date = DateTime.parse(dateString).toLocal();
  return "${date.day}-${date.month}-${date.year}";
}

String _formatTime(String dateString) {
  final date = DateTime.parse(dateString).toLocal();
  return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Case History"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchPatient,
                    decoration: InputDecoration(
                      hintText:
                          "Search patient by name...",
                      prefixIcon:
                          const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredCases.isEmpty
    ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "No Case History Yet",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16),
                          itemCount:
                              filteredCases.length,
                          itemBuilder:
                              (context, index) {

                            final caseItem =
                                filteredCases[index];

                            final hospital =
                                caseItem["hospitalId"];

                            return Container(
                              margin:
                                  const EdgeInsets.only(
                                      bottom: 15),
                              padding:
                                  const EdgeInsets.all(
                                      16),
                              decoration:
                                  BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .grey
                                        .shade300,
                                    blurRadius: 5,
                                    offset:
                                        const Offset(
                                            0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [

                                  // Patient + Status
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Text(
                                        caseItem[
                                                "patientName"] ??
                                            "Unknown",
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              18,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal:
                                                    12,
                                                vertical:
                                                    6),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .green
                                              .shade100,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      20),
                                        ),
                                        child:
                                            const Text(
                                          "COMPLETED",
                                          style:
                                              TextStyle(
                                            color: Colors
                                                .green,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height: 8),

                                  // Patient Location
                                 Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Icon(Icons.location_on, size: 18, color: Colors.red),
    const SizedBox(width: 5),

    Expanded(
      child: Text(
        addressMap[caseItem["_id"]] ?? "Loading address...",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
    ),
  ],
),

                                  const SizedBox(
                                      height: 5),

                                  // Hospital
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons
                                              .local_hospital,
                                          size: 18,
                                          color: Colors
                                              .blue),
                                      const SizedBox(
                                          width: 5),
                                      Text(
                                        hospital != null
                                            ? hospital[
                                                    "hospitalName"] ??
                                                "Hospital"
                                            : "Hospital not available",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height: 5),

                                  // Date & Time
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons
                                              .calendar_today,
                                          size: 16),
                                      const SizedBox(
                                          width: 5),
                                      Text(
                                        "${_formatDate(caseItem["createdAt"])} | ${_formatTime(caseItem["createdAt"])}",
                                      ),
                                    ],
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