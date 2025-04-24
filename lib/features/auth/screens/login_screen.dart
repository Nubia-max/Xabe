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
          // fill available height, then distribute space
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // a flexible top spacer
            const Spacer(flex: 1),

            // your title stays natural size
            const Text(
              'Cast a vote, Create a Legacy!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                // ← here’s your purple text
              ),
            ),

            // small fixed gap
            const SizedBox(height: 20),

            // make the Lottie shrink if needed
            Flexible(
              flex: 4,
              child: SizedBox(
                height: 500,
                child: Lottie.asset(
                  'assets/animations/loginanimation.json',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // replace big fixed gaps with a smaller one
            const SizedBox(height: 20),

            // buttons—if you still overflow, you can wrap these in Flexible too
            const SignInButton(),
            const SizedBox(height: 20),
            const AppleSignInButton(),

            // bottom flexible spacer
            const Spacer(flex: 1),
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
