import 'package:financeapp/controllers/auth_controller.dart';
import 'package:financeapp/screens/setup_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    checkAuth();

    // Future.delayed(
    //   const Duration(milliseconds: 2200),
    //   () => Get.off(() => const MainShell(), transition: Transition.fadeIn),
    // );
  }

  void checkAuth() async {
    bool hasPassword = await authController.checkUserExists();
    if (hasPassword) {
      Get.off(() => LoginScreen(), transition: Transition.fadeIn);
    } else {
      Get.off(() => SetPasswordScreen(), transition: Transition.fadeIn);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B6E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Finance Ledger',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }
}
