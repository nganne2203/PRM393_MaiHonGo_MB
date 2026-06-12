import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: const [
                    BoxShadow(color: Color(0x421F2138), blurRadius: 24)
                  ],
                ),
                alignment: Alignment.center,
                child: Text('桜',
                    style: AppTextStyles.jp(56,
                        color: AppColors.primary, w: FontWeight.w900)),
              ),
              const SizedBox(height: 28),
              Text('Sakura',
                  style: AppTextStyles.h1
                      .copyWith(color: Colors.white, fontSize: 28)),
              const SizedBox(height: 4),
              Text('Learn Japanese, joyfully',
                  style: AppTextStyles.body.copyWith(color: Colors.white70)),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
