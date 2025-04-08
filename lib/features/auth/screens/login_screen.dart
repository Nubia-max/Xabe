import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/core/common/sign_in_button.dart';
import 'package:xabe/core/constants/constants.dart';
import '../controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final bool isWeb = kIsWeb;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Base login content.
    Widget content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, -25),
              child: const Text(
                'Cast a vote, Create a Legacy!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Lottie.asset(
              'assets/animations/loginanimation.json',
              height: 250,
            ),
            const SizedBox(height: 40),
            const SignInButton(),
          ],
        ),
      ),
    );

    // If web and wide, add extra padding and center a fixed-width container.
    if (isWeb && screenWidth > 900) {
      content = Center(
        child: Container(
          width: 900,
          padding: const EdgeInsets.all(40),
          child: content,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          Constants.logoPath,
          height: 40,
        ),
      ),
      body: Obx(() {
        if (authController.isLoading.value) {
          return const Loader();
        } else {
          return content;
        }
      }),
    );
  }
}
