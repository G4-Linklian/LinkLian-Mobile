import 'package:flutter/material.dart';

class AppColors {

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFFD3D3D3); 

  // Primary Palette (Orange/Brown)
  static const Map<int, Color> primaryPalette = {
    100: Color(0xFFFFF2DD),
    200: Color(0xFFFFE3BB),
    300: Color(0xFFFFCF9A),
    400: Color(0xFFFFBC81),
    500: Color(0xFFFF9C57),
    600: Color(0xFFDB763F),
    700: Color(0xFFB7552B),
    800: Color(0xFF93381B),
    900: Color(0xFF7A2310),
  };

  // Button Palette (Blue)
  static const Map<int, Color> buttonPalette = {
    100: Color(0xFFDEF6FF),
    200: Color(0xFFBDEAFF),
    300: Color(0xFF9CDBFF),
    400: Color(0xFF83CBFF),
    500: Color(0xFF5BB2FF),
    600: Color(0xFF428BDB),
    700: Color(0xFF2D68B7),
    800: Color(0xFF1D4993),
    900: Color(0xFF11327A),
  };

  // Success Palette (Green)
  static const Map<int, Color> successPalette = { 
    100: Color(0xFFEFFDDB),
    200: Color(0xFFDBFCB7),
    300: Color(0xFFC0F892),
    400: Color(0xFFA5F176),
    500: Color(0xFF7CE84A),
    600: Color(0xFF5AC736),
    700: Color(0xFF3DA725),
    800: Color(0xFF248617),
    900: Color(0xFF136F0E),
  };

  // Warning Palette (Yellow/Gold)
  static const Map<int, Color> warningPalette = {
    100: Color(0xFFFFF9D8),
    200: Color(0xFFFFF1B1),
    300: Color(0xFFFFE78A),
    400: Color(0xFFFFDE6D),
    500: Color(0xFFFFCE3D),
    600: Color(0xFFDBAA2C),
    700: Color(0xFFB7881E),
    800: Color(0xFF936913),
    900: Color(0xFF7A520B),
  };

  // Danger Palette (Red)
  static const Map<int, Color> dangerPalette = {
    100: Color(0xFFFCF3EF),
    200: Color(0xFFF9D4C7),
    300: Color(0xFFF6C3B8),
    400: Color(0xFFEB6A5E),
    500: Color(0xFFD30000),
    600: Color(0xFF660008),
    700: Color(0xFF51000E),
    800: Color(0xFF3F0010),
    900: Color(0xFF360012),
  };

  // Assignment Status Colors
  static const Color assignmentSubmitted = Color(0xFF3DA725);       // green - ส่งแล้ว
  static const Color assignmentNotSubmitted = AppColors.gray;    // orange - ยังไม่ส่ง
  static const Color assignmentOverdue = Color(0xFFD30000);         // red - ยังไม่ส่งเกินกำหนด
  static const Color assignmentLateSubmitted = Color(0xFFDB763F);   // deep orange - ส่งแล้วเกินกำหนด
}


// color: AppColors.primaryPalette[200],