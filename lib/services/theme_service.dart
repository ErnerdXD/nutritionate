import 'package:flutter/material.dart';

class ThemeService {
  ThemeService._();

  static final instance = ThemeService._();
  final mode = ValueNotifier<ThemeMode>(ThemeMode.light);

  void apply({required bool darkMode}) {
    final next = darkMode ? ThemeMode.dark : ThemeMode.light;
    if (mode.value != next) mode.value = next;
  }
}
