import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/profil_screen.dart';
import '../utils/warna_capify.dart';

class TombolAvatarProfil extends StatelessWidget {
  const TombolAvatarProfil({super.key});

  void bukaHalamanAkun(BuildContext context, bool isSudahMasuk) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) =>
            isSudahMasuk ? const ProfilScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider? authProvider = context.watch<AuthProvider?>();
    bool isSudahMasuk = authProvider?.isSudahMasuk ?? false;
    String inisial = authProvider?.penggunaAktif?.inisial ?? '';

    return IconButton(
      tooltip: isSudahMasuk ? 'Profil & Pengaturan' : 'Masuk ke akun',
      onPressed: () => bukaHalamanAkun(context, isSudahMasuk),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: WarnaCapify.krem,
        child: isSudahMasuk
            ? Text(
                inisial,
                style: const TextStyle(
                  color: WarnaCapify.coklatGelap,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
            : const Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: WarnaCapify.coklatGelap,
              ),
      ),
    );
  }
}
