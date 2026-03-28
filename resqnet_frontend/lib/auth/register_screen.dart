import 'package:flutter/material.dart';
import 'register_user_screen.dart';
import 'hospital_register_screen.dart';
import 'register_ambulance_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  Widget _roleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2C7BE5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 28,
                color: const Color(0xFF2C7BE5),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
  child: Scaffold(
    backgroundColor: Colors.transparent,
      
      body: SafeArea(
  child: Column(
    children: [

      // HEADER
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const Expanded(
              child: Text(
                "Select Account Type",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),

      const SizedBox(height: 10),

      // SCROLL PART
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
          children: [
            _roleCard(
              context,
              "User",
              "Register as individual for emergency access",
              Icons.person,
              const RegisterUserScreen(),
            ),

            _roleCard(
              context,
              "Hospital",
              "Register hospital and manage resources",
              Icons.local_hospital,
              const HospitalRegisterScreen(),
            ),

            _roleCard(
              context,
              "Ambulance Provider",
              "Register ambulance driver for emergency response",
              Icons.local_shipping,
              const RegisterAmbulanceScreen(),
            ),
          ],
        ),
      ),
  ),
    ],
  ),
      ),
  ),
    );
  }
}