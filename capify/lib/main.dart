import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/lagu_dummy.dart';
import 'providers/audio_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/search_provider.dart';
import 'screens/onboarding_screen.dart';
import 'utils/warna_capify.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              AudioProvider()
                ..mulaiAntrian(daftarLaguDummy, isLangsungDiputar: false),
        ),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => SearchProvider()),
        ChangeNotifierProvider(
          create: (context) => PlaylistProvider()..muatKoleksi(),
        ),
      ],
      child: const CapifyApp(),
    ),
  );
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
