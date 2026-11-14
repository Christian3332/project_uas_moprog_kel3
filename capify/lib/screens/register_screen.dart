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
  bool isSetujuSyarat = false;
  bool isSyaratBelumDicentang = false;
  int levelPassword = 0;
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

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
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
      });
      return;
    }

    setState(() => isSedangMendaftar = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => isSedangMendaftar = false);

    Navigator.pop(context, emailController.text.trim());
  }

  Widget buatBarisPersetujuan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: isSetujuSyarat,
              onChanged: isSedangMendaftar
                  ? null
                  : (_) => ubahPersetujuanSyarat(),
              activeColor: WarnaCapify.krem,
              checkColor: WarnaCapify.coklatGelap,
              side: BorderSide(
                color: isSyaratBelumDicentang
                    ? const Color(0xFFFF8A80)
                    : WarnaCapify.krem,
                width: 1.5,
              ),
              visualDensity: VisualDensity.compact,
            ),
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
            padding: EdgeInsets.only(left: 12),
            child: Text(
              'Centang dulu persetujuannya ya',
              style: TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
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
                              cekIsian: cekEmail,
                              isBisaDiketik: !isSedangMendaftar,
                            ),
                            const SizedBox(height: 16),
                            KolomInputAuth(
                              controller: passwordController,
                              petunjukIsian: 'Password',
                              ikonDepan: Icons.lock_outline,
                              isTeksDisembunyikan: isPasswordTersembunyi,
                              jenisAutofill: const [AutofillHints.newPassword],
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
                                    isPasswordTersembunyi =
                                        !isPasswordTersembunyi;
                                  });
                                },
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
                              jenisAutofill: const [AutofillHints.newPassword],
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
                      TombolAuth(
                        teksTombol: 'Daftar',
                        isSedangLoading: isSedangMendaftar,
                        onTekan: prosesDaftar,
                      ),
                      const SizedBox(height: 28),
                      const PemisahAtau(teksTengah: 'atau daftar dengan'),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TombolSosialAuth(
                              ikonLayanan: Icons.g_mobiledata_rounded,
                              namaLayanan: 'Google',
                              onTekan: isSedangMendaftar
                                  ? null
                                  : () => tampilkanPesan(
                                      'Daftar lewat Google segera hadir',
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TombolSosialAuth(
                              ikonLayanan: Icons.facebook_rounded,
                              namaLayanan: 'Facebook',
                              onTekan: isSedangMendaftar
                                  ? null
                                  : () => tampilkanPesan(
                                      'Daftar lewat Facebook segera hadir',
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
