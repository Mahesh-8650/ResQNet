import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome/welcome_screen.dart';
import 'citizen/citizen_home_page.dart';
import 'ambulance/ambulance_home_screen.dart';
import 'hospital/hospital_home_screen.dart';

/// Background message handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
      _firebaseBackgroundHandler);

  SharedPreferences prefs = await SharedPreferences.getInstance();

  bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
String role = prefs.getString("role") ?? "";
String userId = prefs.getString("userId") ?? "";
String hospitalName = prefs.getString("hospitalName") ?? "";
String fullName = prefs.getString("fullName") ?? "";
String vehicleNumber = prefs.getString("vehicleNumber") ?? "";

runApp(
  ResQNetApp(
    isLoggedIn: isLoggedIn,
    role: role,
    userId: userId,
    hospitalName: hospitalName,
    fullName: fullName,
    vehicleNumber: vehicleNumber,
  ),
);
}
class ResQNetApp extends StatelessWidget {

  final bool isLoggedIn;
final String role;
final String userId;
final String hospitalName;
final String fullName;
final String vehicleNumber;

  const ResQNetApp({
  super.key,
  required this.isLoggedIn,
  required this.role,
  required this.userId,
  required this.hospitalName,
  required this.fullName,
  required this.vehicleNumber,
});

 Widget _getHomeScreen() {

  if (role == "citizen") {
    return CitizenHomePage(
      citizenId: userId,
      userName: "",
      email: "",
      phone: "",
      bloodGroup: "",
      dob: "",
      emergencyContact: "",
    );
  }

  if (role == "ambulance") {
    return AmbulanceHomeScreen(
      ambulanceId: userId,
      ambulanceName: fullName,
      vehicleNumber: vehicleNumber,
      isAvailable: false,
      isBusy: false,
    );
  }

  if (role == "hospital") {
    return HospitalHomeScreen(
      hospitalName: hospitalName,
      hospitalId: userId,
    );
  }

  return const WelcomeScreen();
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQNet',
      theme: ThemeData(
        useMaterial3: true,

        // 🔴 Emergency Primary Color
        primaryColor: const Color(0xFFD32F2F),

        scaffoldBackgroundColor: Colors.white,

        colorScheme: const ColorScheme.light(
          primary: Color(0xFFD32F2F),
          secondary: Color(0xFFB71C1C),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F6F8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFD32F2F),
              width: 1.2,
            ),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ),
      home: isLoggedIn
    ? _getHomeScreen()
    : const WelcomeScreen(),
    );
  }
}