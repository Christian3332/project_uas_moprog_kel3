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
  bool isIngatSaya = false;
  bool isEmailSudahDiisi = false;
  AutovalidateMode modeValidasi = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    emailController.addListener(pantauKolomEmail);
  }

  @override
  void dispose() {
    emailController.removeListener(pantauKolomEmail);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void pantauKolomEmail() {
    bool adaIsinya = emailController.text.isNotEmpty;
    if (adaIsinya != isEmailSudahDiisi) {
      setState(() => isEmailSudahDiisi = adaIsinya);
    }
  }

  void ubahIngatSaya() {
    if (isSedangMasuk) return;
    setState(() => isIngatSaya = !isIngatSaya);
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

    String emailPengguna = emailController.text.trim();
    tampilkanPesan(
      isIngatSaya
          ? 'Berhasil masuk, $emailPengguna akan diingat di perangkat ini'
          : 'Berhasil masuk sebagai $emailPengguna',
    );
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
                    AutofillGroup(
                      child: Column(
                        children: [
                          KolomInputAuth(
                            controller: emailController,
                            petunjukIsian: 'Email',
                            ikonDepan: Icons.email_outlined,
                            jenisKeyboard: TextInputType.emailAddress,
                            jenisAutofill: const [AutofillHints.email],
                            cekIsian: cekEmail,
                            isBisaDiketik: !isSedangMasuk,
                            tombolBelakang: isEmailSudahDiisi && !isSedangMasuk
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: WarnaCapify.coklatTua,
                                    ),
                                    onPressed: emailController.clear,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          KolomInputAuth(
                            controller: passwordController,
                            petunjukIsian: 'Password',
                            ikonDepan: Icons.lock_outline,
                            isTeksDisembunyikan: isPasswordTersembunyi,
                            aksiKeyboard: TextInputAction.done,
                            jenisAutofill: const [AutofillHints.password],
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
                                  isPasswordTersembunyi =
                                      !isPasswordTersembunyi;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: isIngatSaya,
                          onChanged: isSedangMasuk
                              ? null
                              : (_) => ubahIngatSaya(),
                          activeColor: WarnaCapify.krem,
                          checkColor: WarnaCapify.coklatGelap,
                          side: const BorderSide(
                            color: WarnaCapify.krem,
                            width: 1.5,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        GestureDetector(
                          onTap: ubahIngatSaya,
                          child: const Text(
                            'Ingat saya',
                            style: TextStyle(
                              color: WarnaCapify.putih,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    TombolAuth(
                      teksTombol: 'Masuk',
                      isSedangLoading: isSedangMasuk,
                      onTekan: prosesMasuk,
                    ),
                    const SizedBox(height: 28),
                    const PemisahAtau(teksTengah: 'atau masuk dengan'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TombolSosialAuth(
                            ikonLayanan: Icons.g_mobiledata_rounded,
                            namaLayanan: 'Google',
                            onTekan: isSedangMasuk
                                ? null
                                : () => tampilkanPesan(
                                    'Masuk lewat Google segera hadir',
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TombolSosialAuth(
                            ikonLayanan: Icons.facebook_rounded,
                            namaLayanan: 'Facebook',
                            onTekan: isSedangMasuk
                                ? null
                                : () => tampilkanPesan(
                                    'Masuk lewat Facebook segera hadir',
                                  ),
                          ),
                        ),
                      ],
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
