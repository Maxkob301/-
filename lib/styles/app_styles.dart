import 'package:flutter/material.dart';

class AppStyles {

  
  static const primaryColor = Colors.black;

  static const accentColor = Colors.orange;

  static const backgroundColor = Color(0xFFF5F5F5);

  static const cardColor = Colors.white;

  static const borderColor = Color(0xFFE0E0E0);

  static const iconColor = Colors.black;

  static const iconSecondary = Colors.grey;

  
  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );

  static const small = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  
  static const buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.black,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.black,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
    );
  }
}