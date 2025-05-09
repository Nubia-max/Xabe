import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final Rx<ThemeMode> mode =
      ThemeMode.system.obs; // Default theme mode is system

  @override
  void onInit() {
    super.onInit();
    ever(mode, (_) => _saveTheme()); // Save theme when it changes
    getTheme(); // Initialize the theme from shared preferences
  }

  bool get isDarkMode {
    if (mode.value == ThemeMode.system) {
      return MediaQuery.of(Get.context!).platformBrightness == Brightness.dark;
    }
    return mode.value == ThemeMode.dark;
  }

  Future<void> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme');

    // Set theme based on saved preference or system default
    mode.value = theme == 'light'
        ? ThemeMode.light
        : theme == 'dark'
            ? ThemeMode.dark
            : MediaQuery.of(Get.context!).platformBrightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light;
  }

  Future<void> _saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme', mode.value == ThemeMode.light ? 'light' : 'dark');
  }

  void toggleTheme() {
    mode.value =
        mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
