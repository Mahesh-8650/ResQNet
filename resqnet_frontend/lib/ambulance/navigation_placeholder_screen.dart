import 'package:flutter/material.dart';

class NavigationPlaceholderScreen extends StatelessWidget {
  final String title;

  const NavigationPlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        title: Text(title),
      ),
      body: const Center(
        child: Text(
          "🚧 In-App Navigation will be implemented in next phase.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}