import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/supabase_config.dart';
import 'data/lagu_dummy.dart';
import 'providers/audio_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/search_provider.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/feed_service.dart';
import 'services/koleksi_service.dart';
import 'services/search_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/supabase_feed_service.dart';
import 'services/supabase_koleksi_service.dart';
import 'services/supabase_search_service.dart';
import 'utils/warna_capify.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isSupabaseSiap = await SupabaseConfig.siapkanSupabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            authService: isSupabaseSiap ? SupabaseAuthService() : AuthService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AudioProvider()
                ..mulaiAntrian(daftarLaguDummy, isLangsungDiputar: false),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeProvider(
            feedService: isSupabaseSiap
                ? const SupabaseFeedService()
                : const FeedService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SearchProvider(
            searchService: isSupabaseSiap
                ? SupabaseSearchService()
                : SearchService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PlaylistProvider(
            koleksiService: isSupabaseSiap
                ? const SupabaseKoleksiService()
                : const KoleksiService(),
          )..muatKoleksi(),
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
