import 'package:flutter/material.dart';

class AppStyles {
  // Title
  static const TextStyle title = TextStyle(
    fontSize: 24,
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );

  // Description
  static const TextStyle description = TextStyle(
    fontSize: 15,
    color: Color(0x70000000),
  );

  // Sub-title
  static const TextStyle subTitle = TextStyle(
    fontSize: 17,
    color: Colors.black,
    fontWeight: FontWeight.w500,
  );

  // Input container decoration
  static final BoxDecoration input = BoxDecoration(
    borderRadius: BorderRadius.circular(13),
    border: Border.all(
      color: const Color(0x30000000),
      width: 0.7,
    ),
  );

  // Input title
  static const TextStyle inputTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  // Text button
  static const TextStyle textButton = TextStyle(
    fontSize: 12,
    color: Color(0xFF004F54),
  );

  // Main Button
  static final BoxDecoration button = BoxDecoration(
    color: const Color(0xFF004F54),
    borderRadius: BorderRadius.circular(13),
  );

  // Button text
  static const TextStyle buttonContent = TextStyle(
    fontSize: 15,
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  // Toggle decoration
  static final BoxDecoration toggleContainer = BoxDecoration(
    color: const Color(0x70E6E6E6),
    borderRadius: BorderRadius.circular(100),
  );

  // Toggle button active
  static final BoxDecoration toggleActive = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(100),
  );

  // Hint text style
  static TextStyle hintText = TextStyle(
    color: Colors.grey.withOpacity(0.5),
  );
}