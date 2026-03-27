import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../emergency/emergency_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
  Color(0xFFD9F3F1), // exact top color
  Color(0xFF77C7C9), // exact bottom color
],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  child: Scaffold(
    backgroundColor: Colors.transparent, // IMPORTANT
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Your existing UI here
              const SizedBox(height: 40),

              // ===== LOGO + APP NAME =====
              Center(
  child: Image.asset(
    "assets/images/image.png", // 👈 your image
    height: 220,
  ),
),

const SizedBox(height: 8),


              const Text(
  "ResQNet",
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black54,
  ),
),

const SizedBox(height: 10),

              // ===== PURPOSE TEXT =====
              const Text(
                'Emergency help,\nwhen you need it.',
                textAlign:TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Quick access to nearby emergency services using your location.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),


              const SizedBox(height: 40),


              // ===== LOGIN BUTTON =====
              Container(
  width: double.infinity,
  height: 55,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    gradient: const LinearGradient(
      colors: [
        Color(0xFF4FACFE),
        Color(0xFF2C7BE5),
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    },
    child: const Text(
      "Login",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  ),
),

              const SizedBox(height: 12),

              // ===== CREATE ACCOUNT =====
              SizedBox(
  width: double.infinity,
  height: 55,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF2C7BE5)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RegisterScreen()),
      );
    },
    child: const Text(
      "Create Account",
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2C7BE5),
      ),
    ),
  ),
),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    );
  }
}