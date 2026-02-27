import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'otp_screen.dart';

class RegisterAmbulanceScreen extends StatefulWidget {
  const RegisterAmbulanceScreen({super.key});

  @override
  State<RegisterAmbulanceScreen> createState() =>
      _RegisterAmbulanceScreenState();
}

class _RegisterAmbulanceScreenState
    extends State<RegisterAmbulanceScreen> {

  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _vehicleNumber = TextEditingController();

  Country _country = Country.parse("IN");

  bool _loading = false;
  bool _obscurePassword = true;

  Uint8List? _licenseBytes;
  Uint8List? _rcBytes;
  Uint8List? _permitBytes;

  String? _licenseName;
  String? _rcName;
  String? _permitName;

  /* ================= FILE PICK ================= */

  Future<void> _pickFile(String type) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result != null) {
      setState(() {
        if (type == "license") {
          _licenseBytes = result.files.single.bytes;
          _licenseName = result.files.single.name;
        } else if (type == "rc") {
          _rcBytes = result.files.single.bytes;
          _rcName = result.files.single.name;
        } else {
          _permitBytes = result.files.single.bytes;
          _permitName = result.files.single.name;
        }
      });
    }
  }

  /* ================= REGISTER ================= */

  Future<void> _registerAmbulance() async {

    if (!_formKey.currentState!.validate()) return;

    if (_licenseBytes == null ||
        _rcBytes == null ||
        _permitBytes == null) {
      _showDialog("Error",
          "Upload License, RC and Permit");
      return;
    }

    setState(() => _loading = true);

    String fullPhone =
        "+${_country.phoneCode}${_phone.text.trim()}";

    try {

      var request = http.MultipartRequest(
        "POST",
        Uri.parse(
            "http://192.168.1.56:5000/api/auth/register/ambulance"),
      );

      request.fields["fullName"] =
          _fullName.text.trim();
      request.fields["email"] =
          _email.text.trim();
      request.fields["password"] =
          _password.text.trim();
      request.fields["phone"] = fullPhone;
      request.fields["licenseNumber"] =
          _licenseNumber.text.trim();
      request.fields["vehicleNumber"] =
          _vehicleNumber.text.trim();

      request.files.add(http.MultipartFile.fromBytes(
        "license",
        _licenseBytes!,
        filename: _licenseName,
      ));

      request.files.add(http.MultipartFile.fromBytes(
        "rc",
        _rcBytes!,
        filename: _rcName,
      ));

      request.files.add(http.MultipartFile.fromBytes(
        "permit",
        _permitBytes!,
        filename: _permitName,
      ));

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
      _showDialog("Error",
          "Server connection failed");
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

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (c) {
        setState(() => _country = c);
      },
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFEDEFF3),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar:
          AppBar(title: const Text("Ambulance Registration")),

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
                  controller: _fullName,
                  decoration:
                      _inputStyle("Full Name"),
                  validator: (v) =>
                      v!.isEmpty ? "Enter full name" : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _email,
                  decoration:
                      _inputStyle("Email"),
                  validator: (v) =>
                      v!.isEmpty ? "Enter email" : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  decoration: _inputStyle("Password")
                      .copyWith(
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
                      v!.length < 8
                          ? "Minimum 8 characters"
                          : null,
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6EDF7),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Text(
                            "+${_country.phoneCode}"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            _inputStyle("Phone Number"),
                        validator: (v) =>
                            v!.isEmpty
                                ? "Enter phone number"
                                : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _licenseNumber,
                  decoration:
                      _inputStyle("License Number"),
                  validator: (v) =>
                      v!.isEmpty
                          ? "Enter license number"
                          : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _vehicleNumber,
                  decoration:
                      _inputStyle("Vehicle Number"),
                  validator: (v) =>
                      v!.isEmpty
                          ? "Enter vehicle number"
                          : null,
                ),

                const SizedBox(height: 20),

                _fileBox(
                    "Upload Driving License",
                    _licenseName,
                    () => _pickFile("license")),

                const SizedBox(height: 12),

                _fileBox("Upload RC",
                    _rcName, () => _pickFile("rc")),

                const SizedBox(height: 12),

                _fileBox("Upload Permit",
                    _permitName,
                    () => _pickFile("permit")),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : _registerAmbulance,
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

  Widget _fileBox(
      String title,
      String? fileName,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 16),
        decoration: BoxDecoration(
          border:
              Border.all(color: Colors.grey),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.upload_file),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName ?? title,
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}