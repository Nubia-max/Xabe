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
          color: Colors.white, // Always white text
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Pallete.greyColor,
        fixedSize: const Size(300, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
