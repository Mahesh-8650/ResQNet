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
      "https://resqnet-oe5z.onrender.com";

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
      // for (var caseItem in allCases) {

      //   final coords = caseItem["patientLocation"]["coordinates"];

      //   double lng = coords[0];
      //   double lat = coords[1];

      //   _getAddress(caseItem["_id"], lat, lng);

      // }

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

// Future<void> _getAddress(String id, double lat, double lng) async {

//   final url =
//       "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=AIzaSyBEn7X8fuoi_O5kRqEH_Hacbf_oCmBYiNw";

//   final response = await http.get(Uri.parse(url));

//   if (response.statusCode == 200) {

//     final data = jsonDecode(response.body);

//     if (data["results"].isNotEmpty) {

//       setState(() {
//         addressMap[id] =
//             data["results"][0]["formatted_address"];
//       });

//     }

//   }
// }

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
        : Column(
            children: [

              /// HEADER (NO BACK BUTTON)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Case History",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              /// SEARCH BAR
              Container(
  margin: const EdgeInsets.symmetric(horizontal: 20),
  child: TextField(
    controller: _searchController,
    onChanged: _searchPatient,
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.search, color: Colors.black54),
      hintText: "Search patient name",
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  ),
),

              const SizedBox(height: 10),

              /// LIST
              Expanded(
                child: filteredCases.isEmpty
                    ? const Center(
                        child: Text(
                          "No Case History Yet",
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        itemCount: filteredCases.length,
                        itemBuilder: (context, index) {

                          final caseItem = filteredCases[index];
                          final hospital = caseItem["hospitalId"];

                          return _caseCard(
                            caseItem["patientName"] ?? "Unknown",
                            (caseItem["patientAddress"] != null &&
 caseItem["patientAddress"].toString().trim().isNotEmpty)
    ? caseItem["patientAddress"]
    : "Address not available",                            
                            hospital != null
                                ? hospital["hospitalName"] ?? "Hospital"
                                : "Hospital not available",
                            "${_formatDate(caseItem["createdAt"])} | ${_formatTime(caseItem["createdAt"])}",
                          );
                        },
                      ),
              ),
            ],
          ),
  ),
),
    );
  }

  Widget _caseCard(
  String name,
  String pickup,
  String hospital,
  String dateTime,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 5)
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
  child: Text(
    name,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "COMPLETED",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(pickup)),
          ],
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            const Icon(Icons.local_hospital,
                color: Colors.blue, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(hospital)),
          ],
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            const Icon(Icons.calendar_today,
                color: Colors.black54, size: 18),
            const SizedBox(width: 6),
            Text(dateTime),
          ],
        ),
      ],
    ),
  );
}

}