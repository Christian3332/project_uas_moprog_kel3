import 'package:flutter/material.dart';

import '../utils/validasi_auth.dart';
import '../utils/warna_capify.dart';
import 'komponen_auth.dart';

class LembarEditNama extends StatefulWidget {
  final String namaSekarang;

  const LembarEditNama({super.key, required this.namaSekarang});

  @override
  State<LembarEditNama> createState() => _LembarEditNamaState();
}

class _LembarEditNamaState extends State<LembarEditNama> {
  final formNamaKey = GlobalKey<FormState>();
  late final TextEditingController namaController;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.namaSekarang);
  }

  @override
  void dispose() {
    namaController.dispose();
    super.dispose();
  }

  void simpanNama() {
    bool isNamaValid = formNamaKey.currentState?.validate() ?? false;
    if (!isNamaValid) return;
    Navigator.pop(context, namaController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    double tinggiKeyboard = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + tinggiKeyboard),
      child: Form(
        key: formNamaKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: WarnaCapify.krem.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ubah Nama',
              style: TextStyle(
                color: WarnaCapify.putih,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nama ini tampil di sapaan beranda dan profilmu.',
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.8),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 20),
            KolomInputAuth(
              controller: namaController,
              petunjukIsian: 'Nama lengkap',
              ikonDepan: Icons.person_outline,
              jenisKeyboard: TextInputType.name,
              aksiKeyboard: TextInputAction.done,
              cekIsian: cekNama,
              saatSelesaiKetik: (_) => simpanNama(),
            ),
            const SizedBox(height: 20),
            TombolAuth(
              teksTombol: 'Simpan',
              isSedangLoading: false,
              onTekan: simpanNama,
            ),
          ],
        ),
      ),
    );
  }
}
