import 'package:flutter/material.dart';

import '../utils/warna_capify.dart';
import 'login_screen.dart';

class IsiSlideOnboarding {
  final IconData ikon;
  final String judul;
  final String deskripsi;

  const IsiSlideOnboarding({
    required this.ikon,
    required this.judul,
    required this.deskripsi,
  });
}

const List<IsiSlideOnboarding> daftarSlideOnboarding = [
  IsiSlideOnboarding(
    ikon: Icons.headphones_rounded,
    judul: 'Dengerin Tanpa Batas',
    deskripsi: 'Dari lagu yang lagi hits sampai lagu nostalgia, semuanya siap nemenin harimu.',
  ),
  IsiSlideOnboarding(
    ikon: Icons.queue_music_rounded,
    judul: 'Playlist Sesuai Mood',
    deskripsi: 'Simpan lagu favoritmu dan susun playlist sendiri buat belajar, olahraga, atau santai.',
  ),
  IsiSlideOnboarding(
    ikon: Icons.explore_rounded,
    judul: 'Temukan Musik Baru',
    deskripsi:
        'Si Capy bakal kasih rekomendasi lagu yang cocok sama selera musikmu.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pengaturSlide = PageController();
  int indexSlideAktif = 0;
  bool isOnboardingSudahSelesai = false;

  bool get isDiSlideTerakhir =>
      indexSlideAktif == daftarSlideOnboarding.length - 1;

  @override
  void dispose() {
    pengaturSlide.dispose();
    super.dispose();
  }

  void pindahKeSlide(int indexTujuan) {
    if (indexTujuan < 0 || indexTujuan >= daftarSlideOnboarding.length) return;
    pengaturSlide.animateToPage(
      indexTujuan,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void tekanTombolUtama() {
    if (isDiSlideTerakhir) {
      selesaikanOnboarding();
    } else {
      pindahKeSlide(indexSlideAktif + 1);
    }
  }

  void selesaikanOnboarding() {
    if (isOnboardingSudahSelesai) return;
    isOnboardingSudahSelesai = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: indexSlideAktif == 0,
      onPopInvokedWithResult: (isSudahKeluar, hasil) {
        if (isSudahKeluar) return;
        pindahKeSlide(indexSlideAktif - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
                child: Row(
                  children: [
                    const Text(
                      'Capify',
                      style: TextStyle(
                        color: WarnaCapify.krem,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Visibility(
                      visible: !isDiSlideTerakhir,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: TextButton(
                        onPressed: () =>
                            pindahKeSlide(daftarSlideOnboarding.length - 1),
                        child: const Text(
                          'Lewati',
                          style: TextStyle(color: WarnaCapify.krem),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: pengaturSlide,
                  itemCount: daftarSlideOnboarding.length,
                  onPageChanged: (indexBaru) {
                    setState(() => indexSlideAktif = indexBaru);
                  },
                  itemBuilder: (context, index) {
                    return SlideOnboarding(
                      isiSlide: daftarSlideOnboarding[index],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(daftarSlideOnboarding.length, (
                        indexTitik,
                      ) {
                        bool isTitikAktif = indexTitik == indexSlideAktif;
                        return GestureDetector(
                          onTap: () => pindahKeSlide(indexTitik),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isTitikAktif ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isTitikAktif
                                  ? WarnaCapify.krem
                                  : WarnaCapify.coklatTua,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: tekanTombolUtama,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WarnaCapify.krem,
                          foregroundColor: WarnaCapify.coklatGelap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Text(
                          isDiSlideTerakhir ? 'Mulai Sekarang' : 'Lanjut',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SlideOnboarding extends StatelessWidget {
  final IsiSlideOnboarding isiSlide;

  const SlideOnboarding({super.key, required this.isiSlide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          children: [
            Container(
              width: 220,
              height: 220,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WarnaCapify.coklatTua.withValues(alpha: 0.6),
              ),
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: WarnaCapify.krem,
                ),
                child: Icon(
                  isiSlide.ikon,
                  size: 72,
                  color: WarnaCapify.coklatGelap,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              isiSlide.judul,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WarnaCapify.putih,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isiSlide.deskripsi,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.85),
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
