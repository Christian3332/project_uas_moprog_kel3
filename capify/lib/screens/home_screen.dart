import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/riwayat_putar_dummy.dart';
import '../models/riwayat_putar.dart';
import '../providers/audio_provider.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  final String namaPengguna;

  const HomeScreen({super.key, this.namaPengguna = 'Capy Lovers'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isHalamanSedangDimuat = true;
  List<RiwayatPutar> riwayatTerakhirDiputar = [];

  @override
  void initState() {
    super.initState();
    muatIsiBeranda();
  }

  Future<void> muatIsiBeranda() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    List<RiwayatPutar> riwayatDariYangTerbaru = List.of(daftarRiwayatPutarDummy)
      ..sort((a, b) => a.jarakSejakDiputar.compareTo(b.jarakSejakDiputar));

    setState(() {
      riwayatTerakhirDiputar = riwayatDariYangTerbaru;
      isHalamanSedangDimuat = false;
    });
  }

  String sapaanSesuaiJam() {
    int jamSekarang = DateTime.now().hour;
    if (jamSekarang >= 4 && jamSekarang < 11) return 'Selamat pagi';
    if (jamSekarang >= 11 && jamSekarang < 15) return 'Selamat siang';
    if (jamSekarang >= 15 && jamSekarang < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  void putarDariRiwayat(int indexRiwayat) {
    if (indexRiwayat < 0 || indexRiwayat >= riwayatTerakhirDiputar.length) {
      return;
    }

    context.read<AudioProvider>().mulaiAntrian(
      riwayatTerakhirDiputar.map((riwayat) => riwayat.lagu).toList(),
      indexMulai: indexRiwayat,
      namaAntrian: 'Terakhir Diputar',
    );
    PlayerScreen.bukaLayarPenuh(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sapaanSesuaiJam(),
              style: const TextStyle(
                fontSize: 13,
                color: WarnaCapify.krem,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              widget.namaPengguna,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                color: WarnaCapify.putih,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: WarnaCapify.krem),
            onPressed: () => tampilkanPesan('Fitur notifikasi segera hadir'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isHalamanSedangDimuat
          ? const Center(
              child: CircularProgressIndicator(color: WarnaCapify.krem),
            )
          : RefreshIndicator(
              color: WarnaCapify.coklatGelap,
              backgroundColor: WarnaCapify.krem,
              onRefresh: muatIsiBeranda,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 12, bottom: 32),
                children: [
                  ...buildBagianTerakhirDiputar(),
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: JudulBagianBeranda(judul: 'Rekomendasi untukmu'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: KotakBelumAdaIsi(
                      ikon: Icons.library_music_outlined,
                      pesan: 'Rekomendasi lagu akan muncul di sini',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> buildBagianTerakhirDiputar() {
    if (riwayatTerakhirDiputar.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: JudulBagianBeranda(judul: 'Terakhir diputar'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: KotakBelumAdaIsi(
            ikon: Icons.history,
            pesan: 'Belum ada lagu yang kamu putar',
          ),
        ),
      ];
    }

    int jumlahSisaRiwayat = riwayatTerakhirDiputar.length - 1;

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: KartuLanjutDengerin(
          riwayat: riwayatTerakhirDiputar.first,
          onTekan: () => putarDariRiwayat(0),
        ),
      ),
      if (jumlahSisaRiwayat > 0) ...[
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: JudulBagianBeranda(judul: 'Terakhir diputar'),
        ),
        SizedBox(
          height: 222,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: jumlahSisaRiwayat,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              int indexAsli = index + 1;
              return KartuLaguTerakhirDiputar(
                riwayat: riwayatTerakhirDiputar[indexAsli],
                onTekan: () => putarDariRiwayat(indexAsli),
              );
            },
          ),
        ),
      ],
    ];
  }
}

class KartuLanjutDengerin extends StatelessWidget {
  final RiwayatPutar riwayat;
  final VoidCallback onTekan;

  const KartuLanjutDengerin({
    super.key,
    required this.riwayat,
    required this.onTekan,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WarnaCapify.coklatTua,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTekan,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CoverAlbum(
                  urlCover: riwayat.lagu.urlCover,
                  lengkungSudut: 10,
                  isPakaiBayangan: false,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lanjut dengerin',
                      style: TextStyle(
                        color: WarnaCapify.krem,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      riwayat.lagu.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WarnaCapify.putih,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${riwayat.lagu.penyanyi} • ${riwayat.teksWaktuDiputar}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: WarnaCapify.krem,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color: WarnaCapify.coklatGelap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KartuLaguTerakhirDiputar extends StatelessWidget {
  final RiwayatPutar riwayat;
  final VoidCallback onTekan;

  const KartuLaguTerakhirDiputar({
    super.key,
    required this.riwayat,
    required this.onTekan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CoverAlbum(
                urlCover: riwayat.lagu.urlCover,
                lengkungSudut: 12,
                isPakaiBayangan: false,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              riwayat.lagu.judul,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WarnaCapify.putih,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              riwayat.lagu.penyanyi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              riwayat.teksWaktuDiputar,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JudulBagianBeranda extends StatelessWidget {
  final String judul;

  const JudulBagianBeranda({super.key, required this.judul});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        judul,
        style: const TextStyle(
          fontSize: 18,
          color: WarnaCapify.putih,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class KotakBelumAdaIsi extends StatelessWidget {
  final IconData ikon;
  final String pesan;

  const KotakBelumAdaIsi({super.key, required this.ikon, required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: WarnaCapify.coklatTua.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ikon, size: 36, color: WarnaCapify.krem),
          const SizedBox(height: 10),
          Text(
            pesan,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WarnaCapify.krem,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
