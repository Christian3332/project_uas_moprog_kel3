import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lagu.dart';
import '../models/racikan_untukmu.dart';
import '../models/riwayat_putar.dart';
import '../providers/audio_provider.dart';
import '../providers/home_provider.dart';
import '../utils/warna_capify.dart';
import '../widgets/komponen_beranda.dart';
import 'detail_playlist_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  final String namaPengguna;

  const HomeScreen({super.key, this.namaPengguna = 'Capy Lovers'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeProvider>().muatIsiBeranda();
    });
  }

  Future<void> segarkanBeranda() async {
    HomeProvider home = context.read<HomeProvider>();
    await home.muatIsiBeranda(isPaksaMuatUlang: true);
    if (!mounted) return;

    String? pesanGagal = home.pesanGagal;
    if (pesanGagal != null) tampilkanPesan(pesanGagal);
  }

  String teksDurasi(Duration durasi) {
    int menit = durasi.inMinutes;
    String detik = (durasi.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
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

  void putarAntrianDariBeranda(
    List<Lagu> antrian,
    int indexLagu,
    String namaAntrian,
  ) {
    if (indexLagu < 0 || indexLagu >= antrian.length) return;

    context.read<AudioProvider>().mulaiAntrian(
      antrian,
      indexMulai: indexLagu,
      namaAntrian: namaAntrian,
    );
    context.read<HomeProvider>().catatLaguDiputar(antrian[indexLagu]);
    PlayerScreen.bukaLayarPenuh(context);
  }

  void putarDariRiwayat(int indexRiwayat) {
    List<Lagu> antrianRiwayat = context
        .read<HomeProvider>()
        .riwayatTerakhirDiputar
        .map((riwayat) => riwayat.lagu)
        .toList();
    putarAntrianDariBeranda(antrianRiwayat, indexRiwayat, 'Terakhir Diputar');
  }

  void putarLaguTemuan(int indexLagu) {
    List<Lagu> antrianTemuan = List.of(
      context.read<HomeProvider>().laguBelumPernahDidengar,
    );
    putarAntrianDariBeranda(antrianTemuan, indexLagu, 'Temuan Baru dari Capy');
  }

  void bukaRacikan(RacikanUntukmu racikan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPlaylistScreen(playlist: racikan.playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    HomeProvider home = context.watch<HomeProvider>();

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
      body: buildIsiBeranda(home),
    );
  }

  Widget buildIsiBeranda(HomeProvider home) {
    String? pesanGagal = home.pesanGagal;

    if (!home.isSudahPernahDimuat && pesanGagal != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: WarnaCapify.krem,
              ),
              const SizedBox(height: 12),
              Text(
                pesanGagal,
                textAlign: TextAlign.center,
                style: const TextStyle(color: WarnaCapify.krem),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: home.muatIsiBeranda,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarnaCapify.krem,
                  foregroundColor: WarnaCapify.coklatGelap,
                ),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (!home.isSudahPernahDimuat) {
      return const Center(
        child: CircularProgressIndicator(color: WarnaCapify.krem),
      );
    }

    return RefreshIndicator(
      color: WarnaCapify.coklatGelap,
      backgroundColor: WarnaCapify.krem,
      onRefresh: segarkanBeranda,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        children: [
          ...buildBagianTerakhirDiputar(home),
          const SizedBox(height: 28),
          ...buildBagianRacikanUntukmu(home.daftarRacikanUntukmu),
          const SizedBox(height: 28),
          ...buildBagianLaguTemuan(home.laguBelumPernahDidengar),
        ],
      ),
    );
  }

  List<Widget> buildBagianTerakhirDiputar(HomeProvider home) {
    RiwayatPutar? laguUntukDilanjutkan = home.laguUntukDilanjutkan;
    List<RiwayatPutar> semuaRiwayat = home.riwayatTerakhirDiputar;

    if (laguUntukDilanjutkan == null) {
      return const [
        JudulBagianBeranda(judul: 'Terakhir diputar'),
        KotakBelumAdaIsi(
          ikon: Icons.history,
          pesan: 'Belum ada lagu yang kamu putar',
        ),
      ];
    }

    int jumlahSisaRiwayat = semuaRiwayat.length - 1;

    return [
      KartuLanjutDengerin(
        riwayat: laguUntukDilanjutkan,
        onTekan: () => putarDariRiwayat(0),
      ),
      if (jumlahSisaRiwayat > 0) ...[
        const SizedBox(height: 28),
        const JudulBagianBeranda(judul: 'Terakhir diputar'),
        RakGeserHorizontal(
          tinggiRak: 222,
          jumlahItem: jumlahSisaRiwayat,
          pembuatItem: (context, index) {
            int indexAsli = index + 1;
            RiwayatPutar riwayat = semuaRiwayat[indexAsli];
            return KartuLaguKecil(
              lagu: riwayat.lagu,
              keterangan: riwayat.teksWaktuDiputar,
              onTekan: () => putarDariRiwayat(indexAsli),
            );
          },
        ),
      ],
    ];
  }

  List<Widget> buildBagianRacikanUntukmu(List<RacikanUntukmu> daftarRacikan) {
    return [
      const JudulBagianBeranda(
        judul: 'Racikan untukmu',
        keterangan: 'Diurutkan dari genre yang paling sering kamu putar',
      ),
      if (daftarRacikan.isEmpty)
        const KotakBelumAdaIsi(
          ikon: Icons.auto_awesome_outlined,
          pesan: 'Capy belum punya racikan buat kamu',
        )
      else
        RakGeserHorizontal(
          tinggiRak: 210,
          jumlahItem: daftarRacikan.length,
          pembuatItem: (context, index) {
            RacikanUntukmu racikan = daftarRacikan[index];
            return KartuRacikanUntukmu(
              racikan: racikan,
              onTekan: () => bukaRacikan(racikan),
            );
          },
        ),
    ];
  }

  List<Widget> buildBagianLaguTemuan(List<Lagu> laguTemuan) {
    return [
      const JudulBagianBeranda(
        judul: 'Belum pernah kamu dengar',
        keterangan: 'Lagu baru pilihan Capy di luar riwayatmu',
      ),
      if (laguTemuan.isEmpty)
        const KotakBelumAdaIsi(
          ikon: Icons.verified_outlined,
          pesan: 'Wah, semua lagu di Capify sudah pernah kamu putar!',
        )
      else
        RakGeserHorizontal(
          tinggiRak: 222,
          jumlahItem: laguTemuan.length,
          pembuatItem: (context, index) {
            Lagu lagu = laguTemuan[index];
            return KartuLaguKecil(
              lagu: lagu,
              keterangan: teksDurasi(lagu.durasi),
              onTekan: () => putarLaguTemuan(index),
            );
          },
        ),
    ];
  }
}
