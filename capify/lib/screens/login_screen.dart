import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/pesan_error_auth.dart';
import '../utils/validasi_auth.dart';
import '../utils/warna_capify.dart';
import '../widgets/komponen_auth.dart';
import 'halaman_utama_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const int batasPasswordSalah = 3;
  static const int lamaPenguncianDetik = 30;

  final formLoginKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordTersembunyi = true;
  bool isSedangMasuk = false;
  bool isIngatSaya = false;
  bool isEmailSudahDiisi = false;
  AutovalidateMode modeValidasi = AutovalidateMode.disabled;

  String? emailBelumTerdaftar;
  String? emailDenganPasswordSalah;
  String? passwordYangSalah;
  bool isSalahnyaBisaDiEmail = false;
  String? pesanErrorUmum;
  int jumlahPasswordSalah = 0;
  int sisaDetikTerkunci = 0;
  Timer? timerPenguncian;

  bool get isSedangTerkunci => sisaDetikTerkunci > 0;

  @override
  void initState() {
    super.initState();
    emailController.addListener(pantauKolomEmail);
  }

  @override
  void dispose() {
    timerPenguncian?.cancel();
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

  String rapikanEmail(String? email) => (email ?? '').trim().toLowerCase();

  String? validasiEmailLogin(String? isian) {
    String? errorFormat = cekEmail(isian);
    if (errorFormat != null) return errorFormat;

    if (rapikanEmail(isian) == emailBelumTerdaftar) {
      return 'Email belum terdaftar, daftar dulu ya';
    }
    return null;
  }

  String? validasiPasswordLogin(String? isian) {
    String? errorFormat = cekPassword(isian);
    if (errorFormat != null) return errorFormat;

    bool isKombinasiYangDitolak =
        isian == passwordYangSalah &&
        rapikanEmail(emailController.text) == emailDenganPasswordSalah;
    if (!isKombinasiYangDitolak) return null;

    if (isSedangTerkunci) {
      return 'Terlalu banyak percobaan, tunggu sebentar ya';
    }
    int sisaPercobaan = batasPasswordSalah - jumlahPasswordSalah;
    String awalanPesan = isSalahnyaBisaDiEmail
        ? 'Email atau password salah'
        : 'Password salah';
    return '$awalanPesan, sisa $sisaPercobaan percobaan lagi';
  }

  void mulaiPenguncian() {
    timerPenguncian?.cancel();
    sisaDetikTerkunci = lamaPenguncianDetik;

    timerPenguncian = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (sisaDetikTerkunci <= 1) {
        timer.cancel();
        setState(() {
          sisaDetikTerkunci = 0;
          jumlahPasswordSalah = 0;
        });
        formLoginKey.currentState?.validate();
        return;
      }

      setState(() => sisaDetikTerkunci--);
    });
  }

  void catatKesalahanMasuk(KesalahanMasuk kesalahan) {
    String? pesanUmum = pesanUmumGagalMasuk(kesalahan);
    if (pesanUmum != null) {
      setState(() => pesanErrorUmum = pesanUmum);
      if (kesalahan == KesalahanMasuk.terlaluSeringMencoba) mulaiPenguncian();
      return;
    }

    setState(() {
      modeValidasi = AutovalidateMode.onUserInteraction;

      if (kesalahan == KesalahanMasuk.emailBelumTerdaftar) {
        emailBelumTerdaftar = rapikanEmail(emailController.text);
      } else {
        isSalahnyaBisaDiEmail =
            kesalahan == KesalahanMasuk.emailAtauPasswordSalah;
        jumlahPasswordSalah++;
        emailDenganPasswordSalah = rapikanEmail(emailController.text);
        passwordYangSalah = passwordController.text;
        if (jumlahPasswordSalah >= batasPasswordSalah) mulaiPenguncian();
      }
    });

    formLoginKey.currentState?.validate();
  }

  Future<void> prosesMasuk() async {
    if (isSedangMasuk || isSedangTerkunci) return;
    FocusScope.of(context).unfocus();

    bool isFormValid = formLoginKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() => modeValidasi = AutovalidateMode.onUserInteraction);
      return;
    }

    AuthProvider authProvider = context.read<AuthProvider>();

    setState(() {
      isSedangMasuk = true;
      pesanErrorUmum = null;
    });
    KesalahanMasuk? kesalahan = await authProvider.masuk(
      email: emailController.text,
      password: passwordController.text,
      isIngatSaya: isIngatSaya,
    );
    if (!mounted) return;
    setState(() => isSedangMasuk = false);

    if (kesalahan != null) {
      catatKesalahanMasuk(kesalahan);
      return;
    }

    timerPenguncian?.cancel();
    bukaHalamanUtama(authProvider.namaTampilan);
  }

  void bukaHalamanUtama(String namaPengguna) {
    ScaffoldMessengerState pengirimPesan = ScaffoldMessenger.of(context);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HalamanUtamaScreen(namaPengguna: namaPengguna),
      ),
      (halamanSebelumnya) => false,
    );

    pengirimPesan
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isIngatSaya
                ? 'Selamat datang, $namaPengguna! Akunmu akan diingat'
                : 'Selamat datang, $namaPengguna!',
          ),
        ),
      );
  }

  Future<void> bukaHalamanDaftar() async {
    String? emailAkunBaru = await Navigator.push(
      context,
      MaterialPageRoute<String>(builder: (context) => const RegisterScreen()),
    );

    if (!mounted || emailAkunBaru == null) return;

    setState(() {
      emailBelumTerdaftar = null;
      emailDenganPasswordSalah = null;
      passwordYangSalah = null;
      isSalahnyaBisaDiEmail = false;
    });
    emailController.text = emailAkunBaru;
    passwordController.clear();
    bool isPerluKonfirmasi = context
        .read<AuthProvider>()
        .isPerluKonfirmasiEmail;
    tampilkanPesan(
      context,
      isPerluKonfirmasi
          ? 'Akun dibuat! Konfirmasi lewat email dulu, lalu masuk'
          : 'Akun berhasil dibuat, silakan masuk',
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isBisaKembali = Navigator.canPop(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isBisaKembali
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: WarnaCapify.putih,
            )
          : null,
      body: Container(
        decoration: latarGradienAuth,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: BatasLebarAuth(
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
                              cekIsian: validasiEmailLogin,
                              isBisaDiketik: !isSedangMasuk,
                              tombolBelakang:
                                  isEmailSudahDiisi && !isSedangMasuk
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
                              cekIsian: validasiPasswordLogin,
                              saatSelesaiKetik: (_) => prosesMasuk(),
                              isBisaDiketik: !isSedangMasuk,
                              tombolBelakang: TombolLihatPassword(
                                isTersembunyi: isPasswordTersembunyi,
                                onTekan: () => setState(
                                  () => isPasswordTersembunyi =
                                      !isPasswordTersembunyi,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          KotakCentangAuth(
                            isDicentang: isIngatSaya,
                            onUbah: isSedangMasuk
                                ? null
                                : (_) => ubahIngatSaya(),
                          ),
                          const SizedBox(width: 10),
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (pesanErrorUmum != null) ...[
                        KotakPesanError(
                          pesan: pesanErrorUmum!,
                          onTutup: () => setState(() => pesanErrorUmum = null),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TombolAuth(
                        teksTombol: isSedangTerkunci
                            ? 'Coba lagi dalam $sisaDetikTerkunci detik'
                            : 'Masuk',
                        isSedangLoading: isSedangMasuk,
                        isNonaktif: isSedangTerkunci,
                        onTekan: prosesMasuk,
                      ),
                      const SizedBox(height: 24),
                      BarisPindahAuth(
                        teksPertanyaan: 'Belum punya akun?',
                        teksTombol: 'Daftar',
                        onTekan: isSedangMasuk ? null : bukaHalamanDaftar,
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
