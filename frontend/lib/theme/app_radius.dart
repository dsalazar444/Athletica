import 'package:flutter/material.dart';

// Class with predefined radius for inputs, buttons, etc.
class AppRadius {
  AppRadius._();

  static const BorderRadius card = BorderRadius.all(Radius.circular(12));
  static const BorderRadius input = BorderRadius.all(Radius.circular(8));
  static const BorderRadius button = BorderRadius.all(Radius.circular(12));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(20));
}