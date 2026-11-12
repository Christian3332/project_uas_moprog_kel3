import 'package:flutter/material.dart';

import '../utils/validasi_auth.dart';
import '../utils/warna_capify.dart';
import '../widgets/komponen_auth.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formLoginKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordTersembunyi = true;
  bool isSedangMasuk = false;
  AutovalidateMode modeValidasi = AutovalidateMode.disabled;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> prosesMasuk() async {
    if (isSedangMasuk) return;
    FocusScope.of(context).unfocus();

    bool isFormValid = formLoginKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() => modeValidasi = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => isSedangMasuk = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => isSedangMasuk = false);

    tampilkanPesan('Berhasil masuk sebagai ${emailController.text.trim()}');
  }

  Future<void> bukaHalamanDaftar() async {
    String? emailAkunBaru = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );

    if (!mounted || emailAkunBaru == null) return;

    emailController.text = emailAkunBaru;
    passwordController.clear();
    tampilkanPesan('Akun berhasil dibuat, silakan masuk');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: latarGradienAuth,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: formLoginKey,
                autovalidateMode: modeValidasi,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HeaderAuth(
                      judul: 'Masuk ke Capify',
                      subjudul: 'Dengerin lagu favoritmu bareng si Capy',
                    ),
                    const SizedBox(height: 40),
                    KolomInputAuth(
                      controller: emailController,
                      petunjukIsian: 'Email',
                      ikonDepan: Icons.email_outlined,
                      jenisKeyboard: TextInputType.emailAddress,
                      cekIsian: cekEmail,
                      isBisaDiketik: !isSedangMasuk,
                    ),
                    const SizedBox(height: 16),
                    KolomInputAuth(
                      controller: passwordController,
                      petunjukIsian: 'Password',
                      ikonDepan: Icons.lock_outline,
                      isTeksDisembunyikan: isPasswordTersembunyi,
                      aksiKeyboard: TextInputAction.done,
                      cekIsian: cekPassword,
                      saatSelesaiKetik: (_) => prosesMasuk(),
                      isBisaDiketik: !isSedangMasuk,
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isSedangMasuk
                            ? null
                            : () => tampilkanPesan(
                                'Fitur lupa password segera hadir',
                              ),
                        child: const Text(
                          'Lupa password?',
                          style: TextStyle(color: WarnaCapify.krem),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TombolAuth(
                      teksTombol: 'Masuk',
                      isSedangLoading: isSedangMasuk,
                      onTekan: prosesMasuk,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun?',
                          style: TextStyle(
                            color: WarnaCapify.putih,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        TextButton(
                          onPressed: isSedangMasuk ? null : bukaHalamanDaftar,
                          child: const Text(
                            'Daftar',
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
    );
  }
}
