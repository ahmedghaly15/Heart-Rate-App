import 'package:flutter/material.dart';
import 'package:heart_rate/screens/splash_screen.dart';
import 'package:heart_rate/utils/app_colors.dart';

class HeartRateApp extends StatelessWidget {
  const HeartRateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heart Rate Monitor',
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
