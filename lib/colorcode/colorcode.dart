import 'package:flutter/material.dart';

class AppColors {
  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF2B5682),
    Color(0xFF24426B),
  ];

  // Individual colors for direct use
  static const Color primaryLight = Color(0xFF2B5682);
  static const Color primaryDark = Color(0xFF24426B);

  // Gradient decoration for easy reuse
  static const BoxDecoration gradientBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: primaryGradient,
    ),
  );
}
