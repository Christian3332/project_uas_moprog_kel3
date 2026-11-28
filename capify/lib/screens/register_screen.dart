import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/pesan_error_auth.dart';
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
  bool isSetujuSyarat = false;
  bool isSyaratBelumDicentang = false;
  int levelPassword = 0;
  String? emailDitolakServer;
  String? pesanEmailDitolakServer;
  String? passwordDitolakServer;
  String? pesanErrorUmum;
  AutovalidateMode modeValidasi = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(pantauKolomPassword);
  }

  @override
  void dispose() {
    passwordController.removeListener(pantauKolomPassword);
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    ulangPasswordController.dispose();
    super.dispose();
  }

  void pantauKolomPassword() {
    int levelBaru = hitungLevelPassword(passwordController.text);
    if (levelBaru != levelPassword) {
      setState(() => levelPassword = levelBaru);
    }
  }

  void ubahPersetujuanSyarat() {
    if (isSedangMendaftar) return;
    setState(() {
      isSetujuSyarat = !isSetujuSyarat;
      if (isSetujuSyarat) isSyaratBelumDicentang = false;
    });
  }

  String? validasiEmailDaftar(String? isian) {
    String? errorFormat = cekEmail(isian);
    if (errorFormat != null) return errorFormat;

    bool isPernahDitolakServer =
        (isian ?? '').trim().toLowerCase() == emailDitolakServer;
    if (isPernahDitolakServer) return pesanEmailDitolakServer;

    if (context.read<AuthProvider>().isEmailSudahTerdaftar(isian ?? '')) {
      return 'Email ini sudah terdaftar, silakan masuk';
    }
    return null;
  }

  String? validasiPasswordDaftar(String? isian) {
    String? errorFormat = cekPassword(isian);
    if (errorFormat != null) return errorFormat;

    String password = isian ?? '';
    if (password.contains(' ')) return 'Password tidak boleh pakai spasi';
    if (password == passwordDitolakServer) {
      return 'Password ditolak server, buat yang lebih kuat';
    }

    String passwordKecil = password.toLowerCase();
    String depanEmail = emailController.text
        .trim()
        .toLowerCase()
        .split('@')
        .first;
    List<String> kataDariNama = namaController.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((kata) => kata.length >= 3)
        .toList();

    if (depanEmail.length >= 3 && passwordKecil.contains(depanEmail)) {
      return 'Password jangan memuat nama emailmu';
    }
    if (kataDariNama.any(passwordKecil.contains)) {
      return 'Password jangan memuat namamu';
    }
    if (hitungLevelPassword(password) < 2) {
      return 'Terlalu lemah, tambahkan angka, huruf besar, atau simbol';
    }
    return null;
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
    if (!isFormValid || !isSetujuSyarat) {
      setState(() {
        modeValidasi = AutovalidateMode.onUserInteraction;
        isSyaratBelumDicentang = !isSetujuSyarat;
        pesanErrorUmum = 'Masih ada isian yang belum benar. Periksa kolom yang ditandai merah.';
      });
      return;
    }

    setState(() {
      isSedangMendaftar = true;
      pesanErrorUmum = null;
    });
    KesalahanDaftar? kesalahan = await context.read<AuthProvider>().daftar(
      nama: namaController.text,
      email: emailController.text,
      password: passwordController.text,
    );
    if (!mounted) return;
    setState(() => isSedangMendaftar = false);

    if (kesalahan == null) {
      Navigator.pop(context, emailController.text.trim().toLowerCase());
      return;
    }

    String? pesanUmum = pesanUmumGagalDaftar(kesalahan);
    if (pesanUmum != null) {
      setState(() => pesanErrorUmum = pesanUmum);
      return;
    }

    setState(() {
      if (kesalahan == KesalahanDaftar.passwordTerlaluLemah) {
        passwordDitolakServer = passwordController.text;
      } else {
        emailDitolakServer = emailController.text.trim().toLowerCase();
        pesanEmailDitolakServer =
            kesalahan == KesalahanDaftar.emailSudahTerdaftar
            ? 'Email ini sudah terdaftar, silakan masuk'
            : 'Email ini tidak bisa dipakai mendaftar, coba email lain';
      }
    });
    formDaftarKey.currentState?.validate();
  }

  Widget buatBarisPersetujuan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            KotakCentangAuth(
              isDicentang: isSetujuSyarat,
              isAdaError: isSyaratBelumDicentang,
              onUbah: isSedangMendaftar ? null : (_) => ubahPersetujuanSyarat(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: ubahPersetujuanSyarat,
                child: const Text.rich(
                  TextSpan(
                    text: 'Saya setuju dengan ',
                    style: TextStyle(
                      color: WarnaCapify.putih,
                      fontWeight: FontWeight.w300,
                    ),
                    children: [
                      TextSpan(
                        text: 'Syarat & Ketentuan',
                        style: TextStyle(
                          color: WarnaCapify.krem,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' Capify'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isSyaratBelumDicentang)
          const Padding(
            padding: EdgeInsets.only(left: 30, top: 4),
            child: Text(
              'Centang dulu persetujuannya ya',
              style: TextStyle(color: warnaPeringatan, fontSize: 12),
            ),
          ),
      ],
    );
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
                child: BatasLebarAuth(
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
                        AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              KolomInputAuth(
                                controller: namaController,
                                petunjukIsian: 'Nama lengkap',
                                ikonDepan: Icons.person_outline,
                                jenisKeyboard: TextInputType.name,
                                jenisAutofill: const [AutofillHints.name],
                                cekIsian: cekNama,
                                isBisaDiketik: !isSedangMendaftar,
                              ),
                              const SizedBox(height: 16),
                              KolomInputAuth(
                                controller: emailController,
                                petunjukIsian: 'Email',
                                ikonDepan: Icons.email_outlined,
                                jenisKeyboard: TextInputType.emailAddress,
                                jenisAutofill: const [AutofillHints.email],
                                cekIsian: validasiEmailDaftar,
                                isBisaDiketik: !isSedangMendaftar,
                              ),
                              const SizedBox(height: 16),
                              KolomInputAuth(
                                controller: passwordController,
                                petunjukIsian: 'Password',
                                ikonDepan: Icons.lock_outline,
                                isTeksDisembunyikan: isPasswordTersembunyi,
                                jenisAutofill: const [
                                  AutofillHints.newPassword,
                                ],
                                cekIsian: validasiPasswordDaftar,
                                isBisaDiketik: !isSedangMendaftar,
                                tombolBelakang: TombolLihatPassword(
                                  isTersembunyi: isPasswordTersembunyi,
                                  onTekan: () => setState(
                                    () => isPasswordTersembunyi =
                                        !isPasswordTersembunyi,
                                  ),
                                ),
                              ),
                              IndikatorKekuatanPassword(
                                levelPassword: levelPassword,
                              ),
                              const SizedBox(height: 16),
                              KolomInputAuth(
                                controller: ulangPasswordController,
                                petunjukIsian: 'Ulangi password',
                                ikonDepan: Icons.lock_reset_outlined,
                                isTeksDisembunyikan: isPasswordTersembunyi,
                                aksiKeyboard: TextInputAction.done,
                                jenisAutofill: const [
                                  AutofillHints.newPassword,
                                ],
                                cekIsian: cekUlangPassword,
                                saatSelesaiKetik: (_) => prosesDaftar(),
                                isBisaDiketik: !isSedangMendaftar,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        buatBarisPersetujuan(),
                        const SizedBox(height: 24),
                        if (pesanErrorUmum != null) ...[
                          KotakPesanError(
                            pesan: pesanErrorUmum!,
                            onTutup: () =>
                                setState(() => pesanErrorUmum = null),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TombolAuth(
                          teksTombol: 'Daftar',
                          isSedangLoading: isSedangMendaftar,
                          onTekan: prosesDaftar,
                        ),
                        const SizedBox(height: 16),
                        BarisPindahAuth(
                          teksPertanyaan: 'Sudah punya akun?',
                          teksTombol: 'Masuk',
                          onTekan: isSedangMendaftar
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ],
                    ),
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
