import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/warna_capify.dart';
import '../widgets/komponen_auth.dart';
import 'halaman_utama_screen.dart';
import 'onboarding_screen.dart';

class CekSesiScreen extends StatefulWidget {
  const CekSesiScreen({super.key});

  @override
  State<CekSesiScreen> createState() => _CekSesiScreenState();
}

class _CekSesiScreenState extends State<CekSesiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => periksaSesi());
  }

  Future<void> periksaSesi() async {
    AuthProvider authProvider = context.read<AuthProvider>();

    await Future.wait([
      authProvider.pulihkanSesi(),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);
    if (!mounted) return;

    Widget halamanTujuan = authProvider.isSudahMasuk
        ? HalamanUtamaScreen(namaPengguna: authProvider.namaTampilan)
        : const OnboardingScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animasiMasuk, animasiKeluar) => halamanTujuan,
        transitionsBuilder:
            (context, animasiMasuk, animasiKeluar, halamanBaru) {
              return FadeTransition(opacity: animasiMasuk, child: halamanBaru);
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: latarGradienAuth,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeaderAuth(
                judul: 'Capify',
                subjudul: 'Menyiapkan musik favoritmu...',
              ),
              SizedBox(height: 32),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: WarnaCapify.krem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
