import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../utils/warna_capify.dart';
import 'komponen_auth.dart';

final GlobalKey<NavigatorState> kunciNavigatorUtama =
    GlobalKey<NavigatorState>();

class PenjagaPemutar extends StatefulWidget {
  final Widget child;

  const PenjagaPemutar({super.key, required this.child});

  @override
  State<PenjagaPemutar> createState() => _PenjagaPemutarState();
}

class _PenjagaPemutarState extends State<PenjagaPemutar> {
  late final AuthProvider authProvider;
  late final AudioProvider audioProvider;
  int jumlahPenolakanTerakhir = 0;
  bool isAjakanSedangTampil = false;

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    audioProvider = context.read<AudioProvider>();
    jumlahPenolakanTerakhir = audioProvider.jumlahPutarDitolak;

    authProvider.addListener(samakanIzinDenganLogin);
    audioProvider.addListener(cekPenolakanBaru);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => samakanIzinDenganLogin(),
    );
  }

  @override
  void dispose() {
    authProvider.removeListener(samakanIzinDenganLogin);
    audioProvider.removeListener(cekPenolakanBaru);
    super.dispose();
  }

  void samakanIzinDenganLogin() {
    audioProvider.aturIzinPemutaran(authProvider.isSudahMasuk);
  }

  void cekPenolakanBaru() {
    int jumlahSekarang = audioProvider.jumlahPutarDitolak;
    if (jumlahSekarang == jumlahPenolakanTerakhir) return;

    jumlahPenolakanTerakhir = jumlahSekarang;
    if (isAjakanSedangTampil) return;
    Future.microtask(tampilkanAjakanMasuk);
  }

  Future<void> tampilkanAjakanMasuk() async {
    NavigatorState? navigatorUtama = kunciNavigatorUtama.currentState;
    BuildContext? konteksOverlay = navigatorUtama?.overlay?.context;
    if (!mounted || navigatorUtama == null || konteksOverlay == null) return;

    isAjakanSedangTampil = true;
    bool? isMauMasuk = await showModalBottomSheet<bool>(
      context: konteksOverlay,
      backgroundColor: WarnaCapify.coklatGelap,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (konteksLembar) => const LembarAjakanMasuk(),
    );
    isAjakanSedangTampil = false;

    if (!mounted || isMauMasuk != true) return;
    navigatorUtama.push(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class LembarAjakanMasuk extends StatelessWidget {
  const LembarAjakanMasuk({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WarnaCapify.krem.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: WarnaCapify.krem,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 34,
                color: WarnaCapify.coklatGelap,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Masuk dulu, yuk!',
              style: TextStyle(
                color: WarnaCapify.putih,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lagu di Capify cuma bisa diputar setelah kamu masuk ke akun. '
              'Daftarnya gratis kok!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TombolAuth(
              teksTombol: 'Masuk atau Daftar',
              isSedangLoading: false,
              onTekan: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Nanti saja',
                style: TextStyle(color: WarnaCapify.krem),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
