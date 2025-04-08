import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';

class Constants {
  static const logoPath = 'assets/images/logo.png';
  static const loginEmotePath = 'assets/images/loginEmote.png';
  static const googlePath = 'assets/images/google.png';

  static const bannerDefault = 'assets/images/banner.jpeg';
  static const avatarDefault = 'assets/images/logo.png';

  static final List<Widget> tabWidgets = [
    HomeScreen(),
  ];

  static const IconData up =
      IconData(0xe800, fontFamily: 'MyFlutterApp', fontPackage: null);
  static const IconData down =
      IconData(0xe801, fontFamily: 'MyFlutterApp', fontPackage: null);
}
