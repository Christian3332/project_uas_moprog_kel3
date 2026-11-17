import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/kategori_dummy.dart';
import '../data/lagu_per_kategori_dummy.dart';
import '../data/riwayat_putar_dummy.dart';
import '../models/kategori_musik.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';
import '../models/racikan_untukmu.dart';
import '../models/riwayat_putar.dart';
import '../providers/audio_provider.dart';
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
  bool isHalamanSedangDimuat = true;
  List<RiwayatPutar> riwayatTerakhirDiputar = [];
  List<RacikanUntukmu> daftarRacikanUntukmu = [];
  List<Lagu> laguBelumPernahDidengar = [];

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

    Set<String> laguYangPernahDiputar = riwayatDariYangTerbaru
        .map((riwayat) => kunciLagu(riwayat.lagu))
        .toSet();

    setState(() {
      riwayatTerakhirDiputar = riwayatDariYangTerbaru;
      daftarRacikanUntukmu = racikPlaylistDariKategori(laguYangPernahDiputar);
      laguBelumPernahDidengar = cariLaguYangBelumDidengar(
        laguYangPernahDiputar,
      );
      isHalamanSedangDimuat = false;
    });
  }

  String kunciLagu(Lagu lagu) => '${lagu.judul}|${lagu.penyanyi}';

  List<RacikanUntukmu> racikPlaylistDariKategori(
    Set<String> laguYangPernahDiputar,
  ) {
    List<RacikanUntukmu> hasilRacikan = [];

    laguPerKategoriDummy.forEach((namaKategori, isiLagu) {
      if (isiLagu.isEmpty) return;

      int jumlahFamiliar = isiLagu
          .where((lagu) => laguYangPernahDiputar.contains(kunciLagu(lagu)))
          .length;

      hasilRacikan.add(
        RacikanUntukmu(
          playlist: Playlist(
            nama: 'Racikan $namaKategori',
            deskripsi: rangkumPenyanyi(isiLagu),
            daftarLagu: isiLagu,
          ),
          warnaAksen: cariWarnaKategori(namaKategori),
          jumlahLaguFamiliar: jumlahFamiliar,
        ),
      );
    });

    List<RacikanUntukmu> urutanAwal = List.of(hasilRacikan);
    hasilRacikan.sort((a, b) {
      int selisihFamiliar = b.jumlahLaguFamiliar - a.jumlahLaguFamiliar;
      if (selisihFamiliar != 0) return selisihFamiliar;
      return urutanAwal.indexOf(a) - urutanAwal.indexOf(b);
    });

    return hasilRacikan;
  }

  String rangkumPenyanyi(List<Lagu> isiLagu) {
    List<String> penyanyiTanpaDobel = [];
    for (Lagu lagu in isiLagu) {
      if (!penyanyiTanpaDobel.contains(lagu.penyanyi)) {
        penyanyiTanpaDobel.add(lagu.penyanyi);
      }
    }

    if (penyanyiTanpaDobel.length == 1) {
      return 'Spesial dari ${penyanyiTanpaDobel.first}';
    }
    if (penyanyiTanpaDobel.length == 2) {
      return '${penyanyiTanpaDobel[0]} dan ${penyanyiTanpaDobel[1]}';
    }
    return '${penyanyiTanpaDobel[0]}, ${penyanyiTanpaDobel[1]}, dan lainnya';
  }

  Color cariWarnaKategori(String namaKategori) {
    for (KategoriMusik kategori in daftarKategoriDummy) {
      if (kategori.nama == namaKategori) return kategori.warnaKartu;
    }
    return WarnaCapify.coklatTua;
  }

  List<Lagu> cariLaguYangBelumDidengar(Set<String> laguYangPernahDiputar) {
    List<Lagu> hasilTemuan = [];
    Set<String> laguYangSudahMasuk = {};

    for (List<Lagu> isiLagu in laguPerKategoriDummy.values) {
      for (Lagu lagu in isiLagu) {
        String kunci = kunciLagu(lagu);
        bool isPernahDiputar = laguYangPernahDiputar.contains(kunci);
        bool isSudahMasukDaftar = laguYangSudahMasuk.contains(kunci);

        if (!isPernahDiputar && !isSudahMasukDaftar) {
          hasilTemuan.add(lagu);
          laguYangSudahMasuk.add(kunci);
        }
      }
    }

    return hasilTemuan;
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

  void putarLaguTemuan(int indexLagu) {
    if (indexLagu < 0 || indexLagu >= laguBelumPernahDidengar.length) return;

    context.read<AudioProvider>().mulaiAntrian(
      laguBelumPernahDidengar,
      indexMulai: indexLagu,
      namaAntrian: 'Temuan Baru dari Capy',
    );
    PlayerScreen.bukaLayarPenuh(context);
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
                  ...buildBagianRacikanUntukmu(),
                  const SizedBox(height: 28),
                  ...buildBagianLaguTemuan(),
                ],
              ),
            ),
    );
  }

  List<Widget> buildBagianTerakhirDiputar() {
    if (riwayatTerakhirDiputar.isEmpty) {
      return const [
        JudulBagianBeranda(judul: 'Terakhir diputar'),
        KotakBelumAdaIsi(
          ikon: Icons.history,
          pesan: 'Belum ada lagu yang kamu putar',
        ),
      ];
    }

    int jumlahSisaRiwayat = riwayatTerakhirDiputar.length - 1;

    return [
      KartuLanjutDengerin(
        riwayat: riwayatTerakhirDiputar.first,
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
            RiwayatPutar riwayat = riwayatTerakhirDiputar[indexAsli];
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

  List<Widget> buildBagianRacikanUntukmu() {
    return [
      const JudulBagianBeranda(
        judul: 'Racikan untukmu',
        keterangan: 'Diurutkan dari genre yang paling sering kamu putar',
      ),
      if (daftarRacikanUntukmu.isEmpty)
        const KotakBelumAdaIsi(
          ikon: Icons.auto_awesome_outlined,
          pesan: 'Capy belum punya racikan buat kamu',
        )
      else
        RakGeserHorizontal(
          tinggiRak: 210,
          jumlahItem: daftarRacikanUntukmu.length,
          pembuatItem: (context, index) {
            RacikanUntukmu racikan = daftarRacikanUntukmu[index];
            return KartuRacikanUntukmu(
              racikan: racikan,
              onTekan: () => bukaRacikan(racikan),
            );
          },
        ),
    ];
  }

  List<Widget> buildBagianLaguTemuan() {
    return [
      const JudulBagianBeranda(
        judul: 'Belum pernah kamu dengar',
        keterangan: 'Lagu baru pilihan Capy di luar riwayatmu',
      ),
      if (laguBelumPernahDidengar.isEmpty)
        const KotakBelumAdaIsi(
          ikon: Icons.verified_outlined,
          pesan: 'Wah, semua lagu di Capify sudah pernah kamu putar!',
        )
      else
        RakGeserHorizontal(
          tinggiRak: 222,
          jumlahItem: laguBelumPernahDidengar.length,
          pembuatItem: (context, index) {
            Lagu lagu = laguBelumPernahDidengar[index];
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
