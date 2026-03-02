import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'otp_screen.dart';

class HospitalRegisterScreen extends StatefulWidget {
  const HospitalRegisterScreen({super.key});

  @override
  State<HospitalRegisterScreen> createState() =>
      _HospitalRegisterScreenState();
}

class _HospitalRegisterScreenState
    extends State<HospitalRegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final _hospitalName = TextEditingController();
  final _registrationNumber = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _addressController = TextEditingController();

  Country _country = Country.parse("IN");

  bool _loading = false;
  bool _obscurePassword = true;
  bool _isDetectingLocation = false;

  double? _latitude;
  double? _longitude;

  Uint8List? _certificateBytes;
  String? _certificateName;

  /* ================= LOCATION DETECTION ================= */

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);

    try {
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showDialog("Permission Denied",
            "Location permission permanently denied.");
        setState(() => _isDetectingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _latitude = position.latitude;
      _longitude = position.longitude;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
              _latitude!, _longitude!);

      Placemark place = placemarks.first;

      String readableAddress =
          "${place.street ?? ''}, "
          "${place.locality ?? ''}, "
          "${place.postalCode ?? ''}, "
          "${place.administrativeArea ?? ''}, "
          "${place.country ?? ''}";

      setState(() {
        _addressController.text = readableAddress;
        _isDetectingLocation = false;
      });

    } catch (e) {
      _showDialog("Error", "Failed to detect location");
      setState(() => _isDetectingLocation = false);
    }
  }

  /* ================= FILE PICK ================= */

  Future<void> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result != null) {
      setState(() {
        _certificateBytes = result.files.single.bytes;
        _certificateName = result.files.single.name;
      });
    }
  }

  /* ================= REGISTER ================= */

  Future<void> _registerHospital() async {

    if (!_formKey.currentState!.validate()) return;

    if (_certificateBytes == null) {
      _showDialog("Error",
          "Please upload registration certificate");
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showDialog("Error",
          "Please detect hospital location");
      return;
    }

    setState(() => _loading = true);

    String fullPhone =
        "+${_country.phoneCode}${_phone.text.trim()}";

    try {

      var request = http.MultipartRequest(
        "POST",
        Uri.parse(
            "https://resqnet-backend-1xe3.onrender.com/api/auth/register/hospital"),
      );

      request.fields["hospitalName"] =
          _hospitalName.text.trim();
      request.fields["registrationNumber"] =
          _registrationNumber.text.trim();
      request.fields["email"] =
          _email.text.trim();
      request.fields["password"] =
          _password.text.trim();
      request.fields["phone"] = fullPhone;
      request.fields["address"] =
          _addressController.text.trim();
      request.fields["latitude"] =
          _latitude.toString();
      request.fields["longitude"] =
          _longitude.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          "certificate",
          _certificateBytes!,
          filename: _certificateName,
        ),
      );

      var response = await request.send();
      var responseData =
          await response.stream.bytesToString();
      var decoded = json.decode(responseData);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phone: fullPhone,
              isRegisterFlow: true,
            ),
          ),
        );
      } else {
        _showDialog(
          "Error",
          decoded["message"] ?? "Registration failed",
        );
      }

    } catch (e) {
      _showDialog("Error", "Server connection failed");
    }

    setState(() => _loading = false);
  }

  /* ================= DIALOG ================= */

  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  /* ================= COUNTRY PICKER ================= */

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (c) {
        setState(() => _country = c);
      },
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar:
          AppBar(title: const Text("Hospital Registration")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),

          child: Form(
            key: _formKey,
            child: Column(
              children: [

                TextFormField(
                  controller: _hospitalName,
                  decoration:
                      const InputDecoration(labelText: "Hospital Name"),
                  validator: (v) =>
                      v!.isEmpty ? "Enter hospital name" : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _registrationNumber,
                  decoration:
                      const InputDecoration(labelText: "Registration Number"),
                  validator: (v) =>
                      v!.isEmpty ? "Enter registration number" : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _email,
                  decoration:
                      const InputDecoration(labelText: "Email"),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Enter email";
                    }
                    if (!v.contains("@")) {
                      return "Enter valid email";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 8
                          ? "Minimum 8 characters"
                          : null,
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6EDF7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text("+${_country.phoneCode}"),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: "Phone Number"),
                        validator: (v) =>
                            v!.isEmpty ? "Enter phone number" : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _addressController,
                  readOnly: true,
                  decoration: const InputDecoration(
                      labelText: "Hospital Address"),
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _isDetectingLocation
                      ? null
                      : _detectLocation,
                  icon: const Icon(Icons.location_on),
                  label: _isDetectingLocation
                      ? const Text("Detecting...")
                      : const Text("Detect Current Location"),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _certificateBytes == null
                                ? "Upload Registration Certificate"
                                : _certificateName!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _loading ? null : _registerHospital,
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text("Register"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}