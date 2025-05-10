import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    ever(mode, (_) => _saveTheme());
    _loadTheme(); // renamed for clarity
  }

  bool get isDarkMode {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (mode.value == ThemeMode.system) {
      return brightness == Brightness.dark;
    }
    return mode.value == ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme');

    if (theme == 'light') {
      mode.value = ThemeMode.light;
    } else if (theme == 'dark') {
      mode.value = ThemeMode.dark;
    } else {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      mode.value =
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }
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
