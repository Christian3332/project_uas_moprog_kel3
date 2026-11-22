import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/kategori_dummy.dart';
import '../models/kategori_musik.dart';
import '../providers/home_provider.dart';
import '../utils/warna_capify.dart';
import 'halaman_utama_screen.dart';

class PreferensiGenreScreen extends StatefulWidget {
  final bool isDariOnboarding;

  const PreferensiGenreScreen({super.key, this.isDariOnboarding = false});

  @override
  State<PreferensiGenreScreen> createState() => _PreferensiGenreScreenState();
}

class _PreferensiGenreScreenState extends State<PreferensiGenreScreen> {
  static const double batasTinggiLayarPendek = 480;

  List<String> genreDipilih = [];
  bool isSedangMenyimpan = false;

  @override
  void initState() {
    super.initState();
    genreDipilih = List.of(context.read<HomeProvider>().genreFavorit);
  }

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  void pilihAtauBatalkanGenre(String namaGenre) {
    if (genreDipilih.contains(namaGenre)) {
      setState(() => genreDipilih.remove(namaGenre));
      return;
    }

    if (genreDipilih.length >= HomeProvider.batasGenreFavorit) {
      tampilkanPesan(
        'Maksimal ${HomeProvider.batasGenreFavorit} genre ya, batalkan salah satu dulu',
      );
      return;
    }

    setState(() => genreDipilih.add(namaGenre));
  }

  void simpanPilihan() {
    if (isSedangMenyimpan || genreDipilih.isEmpty) return;
    isSedangMenyimpan = true;

    context.read<HomeProvider>().simpanGenreFavorit(genreDipilih);

    if (widget.isDariOnboarding) {
      masukKeBeranda();
    } else {
      Navigator.pop(context, true);
    }
  }

  void lewatiPilihan() {
    if (isSedangMenyimpan) return;
    isSedangMenyimpan = true;
    masukKeBeranda();
  }

  void masukKeBeranda() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animasiMasuk, animasiKeluar) {
          return const HalamanUtamaScreen();
        },
        transitionsBuilder:
            (context, animasiMasuk, animasiKeluar, halamanTujuan) {
              return FadeTransition(
                opacity: animasiMasuk,
                child: halamanTujuan,
              );
            },
      ),
      (ruteSebelumnya) => false,
    );
  }

  int? nomorUrutGenre(String namaGenre) {
    int posisi = genreDipilih.indexOf(namaGenre);
    if (posisi == -1) return null;
    return posisi + 1;
  }

  @override
  Widget build(BuildContext context) {
    bool isBelumAdaYangDipilih = genreDipilih.isEmpty;
    double tinggiKartuGenre = 32 + MediaQuery.textScalerOf(context).scale(26);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        foregroundColor: WarnaCapify.putih,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (widget.isDariOnboarding)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.5,
              ),
              child: TextButton(
                onPressed: lewatiPilihan,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Lewati dulu',
                    style: TextStyle(color: WarnaCapify.krem),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, batasUkuran) {
            bool isLayarPendek = batasUkuran.maxHeight < batasTinggiLayarPendek;

            Widget bagianTombolSimpan = Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Text(
                    isBelumAdaYangDipilih
                        ? 'Belum ada genre yang dipilih'
                        : '${genreDipilih.length} dari ${HomeProvider.batasGenreFavorit} genre dipilih',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WarnaCapify.krem,
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isBelumAdaYangDipilih ? null : simpanPilihan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WarnaCapify.krem,
                          foregroundColor: WarnaCapify.coklatGelap,
                          disabledBackgroundColor: WarnaCapify.coklatTua,
                          disabledForegroundColor: Colors.white38,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Text(
                          widget.isDariOnboarding
                              ? 'Simpan & Mulai'
                              : 'Simpan Preferensi',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            Widget areaGulir = CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Genre apa yang kamu suka?',
                          style: TextStyle(
                            color: WarnaCapify.putih,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pilih 1 sampai ${HomeProvider.batasGenreFavorit} genre. '
                          'Yang kamu pilih duluan bakal jadi prioritas racikan Capy.',
                          style: TextStyle(
                            color: WarnaCapify.krem.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: tinggiKartuGenre,
                    ),
                    itemCount: daftarKategoriDummy.length,
                    itemBuilder: (context, index) {
                      KategoriMusik kategori = daftarKategoriDummy[index];
                      return KartuPilihanGenre(
                        kategori: kategori,
                        nomorUrut: nomorUrutGenre(kategori.nama),
                        onTekan: () => pilihAtauBatalkanGenre(kategori.nama),
                      );
                    },
                  ),
                ),
                if (isLayarPendek)
                  SliverToBoxAdapter(child: bagianTombolSimpan),
              ],
            );

            if (isLayarPendek) return areaGulir;

            return Column(
              children: [
                Expanded(child: areaGulir),
                bagianTombolSimpan,
              ],
            );
          },
        ),
      ),
    );
  }
}

class KartuPilihanGenre extends StatelessWidget {
  final KategoriMusik kategori;
  final int? nomorUrut;
  final VoidCallback onTekan;

  const KartuPilihanGenre({
    super.key,
    required this.kategori,
    required this.nomorUrut,
    required this.onTekan,
  });

  @override
  Widget build(BuildContext context) {
    int? nomor = nomorUrut;
    bool isDipilih = nomor != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDipilih
            ? kategori.warnaKartu
            : kategori.warnaKartu.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDipilih ? WarnaCapify.krem : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTekan,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(kategori.ikon, color: WarnaCapify.putih, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kategori.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WarnaCapify.putih,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (nomor != null)
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: WarnaCapify.krem,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$nomor',
                      style: const TextStyle(
                        color: WarnaCapify.coklatGelap,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
