import 'package:flutter/material.dart';

import '../utils/validasi_auth.dart';
import '../utils/warna_capify.dart';
import '../widgets/komponen_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formDaftarKey = GlobalKey<FormState>();
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ulangPasswordController = TextEditingController();

  bool isPasswordTersembunyi = true;
  bool isSedangMendaftar = false;
  AutovalidateMode modeValidasi = AutovalidateMode.disabled;

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    ulangPasswordController.dispose();
    super.dispose();
  }

  String? cekUlangPassword(String? isian) {
    if ((isian ?? '').isEmpty) return 'Ketik ulang password kamu';
    if (isian != passwordController.text) return 'Password tidak sama';
    return null;
  }

  Future<void> prosesDaftar() async {
    if (isSedangMendaftar) return;
    FocusScope.of(context).unfocus();

    bool isFormValid = formDaftarKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() => modeValidasi = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => isSedangMendaftar = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => isSedangMendaftar = false);

    Navigator.pop(context, emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isSedangMendaftar,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: WarnaCapify.putih,
        ),
        body: Container(
          decoration: latarGradienAuth,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: formDaftarKey,
                  autovalidateMode: modeValidasi,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HeaderAuth(
                        judul: 'Buat Akun Baru',
                        subjudul: 'Gabung Capify dan mulai bikin playlist-mu',
                      ),
                      const SizedBox(height: 32),
                      KolomInputAuth(
                        controller: namaController,
                        petunjukIsian: 'Nama lengkap',
                        ikonDepan: Icons.person_outline,
                        jenisKeyboard: TextInputType.name,
                        cekIsian: cekNama,
                        isBisaDiketik: !isSedangMendaftar,
                      ),
                      const SizedBox(height: 16),
                      KolomInputAuth(
                        controller: emailController,
                        petunjukIsian: 'Email',
                        ikonDepan: Icons.email_outlined,
                        jenisKeyboard: TextInputType.emailAddress,
                        cekIsian: cekEmail,
                        isBisaDiketik: !isSedangMendaftar,
                      ),
                      const SizedBox(height: 16),
                      KolomInputAuth(
                        controller: passwordController,
                        petunjukIsian: 'Password',
                        ikonDepan: Icons.lock_outline,
                        isTeksDisembunyikan: isPasswordTersembunyi,
                        cekIsian: cekPassword,
                        isBisaDiketik: !isSedangMendaftar,
                        tombolBelakang: IconButton(
                          icon: Icon(
                            isPasswordTersembunyi
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: WarnaCapify.coklatTua,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordTersembunyi = !isPasswordTersembunyi;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      KolomInputAuth(
                        controller: ulangPasswordController,
                        petunjukIsian: 'Ulangi password',
                        ikonDepan: Icons.lock_reset_outlined,
                        isTeksDisembunyikan: isPasswordTersembunyi,
                        aksiKeyboard: TextInputAction.done,
                        cekIsian: cekUlangPassword,
                        saatSelesaiKetik: (_) => prosesDaftar(),
                        isBisaDiketik: !isSedangMendaftar,
                      ),
                      const SizedBox(height: 32),
                      TombolAuth(
                        teksTombol: 'Daftar',
                        isSedangLoading: isSedangMendaftar,
                        onTekan: prosesDaftar,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun?',
                            style: TextStyle(
                              color: WarnaCapify.putih,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          TextButton(
                            onPressed: isSedangMendaftar
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                color: WarnaCapify.krem,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
