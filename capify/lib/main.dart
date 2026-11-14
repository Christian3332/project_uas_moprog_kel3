import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'utils/warna_capify.dart';

void main() {
  runApp(const CapifyApp());
}

class CapifyApp extends StatelessWidget {
  const CapifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: WarnaCapify.coklatGelap,
        colorScheme: const ColorScheme.dark(
          primary: WarnaCapify.krem,
          surface: WarnaCapify.coklatGelap,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: WarnaCapify.krem,
          contentTextStyle: TextStyle(color: WarnaCapify.coklatGelap),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
