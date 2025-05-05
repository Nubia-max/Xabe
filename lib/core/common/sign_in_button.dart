import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/theme/pallete.dart';
import '../../features/auth/controller/auth_controller.dart';
import '../constants/constants.dart';

class SignInButton extends StatelessWidget {
  final bool isFromLogin;
  const SignInButton({super.key, this.isFromLogin = true});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Get.find<AuthController>().signInWithGoogle(isFromLogin);
      },
      icon: Image.asset(
        Constants.googlePath,
        width: 35,
      ),
      label: const Text(
        'Continue with Google',
        style: TextStyle(
          fontSize: 18,
          color: Colors.black, // Always white text
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Pallete.whiteColor,
        fixedSize: const Size(300, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class AppleSignInButton extends StatelessWidget {
  final bool isFromLogin;

  const AppleSignInButton({super.key, this.isFromLogin = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      onPressed: () {
        Get.find<AuthController>().signInWithApple(isFromLogin);
      },
      icon: Image.asset(
        Constants.applePath,
        width: 26,
      ),
      label: const Text(
        'Sign in with Apple',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white, // Always white text
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? Pallete.greyColor // use grey in dark mode
            : Pallete.blackColor, // otherwise black
        fixedSize: const Size(300, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
