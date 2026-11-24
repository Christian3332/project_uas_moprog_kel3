import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/feed_beranda.dart';
import '../models/lagu.dart';
import '../models/racikan_untukmu.dart';
import '../models/riwayat_putar.dart';
import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../utils/gaya_teks_beranda.dart';
import '../utils/kunci_lagu.dart';
import '../utils/warna_capify.dart';
import '../widgets/komponen_beranda.dart';
import '../widgets/tombol_avatar_profil.dart';
import 'detail_playlist_screen.dart';
import 'player_screen.dart';
import 'preferensi_genre_screen.dart';

class HomeScreen extends StatefulWidget {
  final String namaPengguna;

  const HomeScreen({super.key, this.namaPengguna = 'Capy Lovers'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const String namaAntrianRiwayat = 'Terakhir Diputar';
  static const String namaAntrianTemuan = 'Temuan Baru dari Capy';

  bool isSedangTarikSegarkan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HomeProvider home = context.read<HomeProvider>();
      home.pantauPemutar(context.read<AudioProvider>());
      home.muatIsiBeranda();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    cobaLagiSaatAplikasiDibukaKembali();
  }

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  String pesanDariHasilSegarkan(HasilSegarkan hasil, HomeProvider home) {
    return switch (hasil) {
      HasilSegarkan.diperbarui => 'Beranda sudah diperbarui',
      HasilSegarkan.tidakAdaPerubahan => 'Berandamu sudah yang paling baru',
      HasilSegarkan.terlaluCepat =>
        'Beranda baru saja diperbarui, coba lagi sebentar lagi ya',
      HasilSegarkan.masihOffline =>
        'Masih offline, cek Wi-Fi atau data selulermu dulu ya',
      HasilSegarkan.masihCadangan =>
        'Server masih belum bisa dihubungi, coba lagi nanti ya',
      HasilSegarkan.gagal =>
        home.pesanGagal ?? 'Beranda gagal dimuat, coba lagi sebentar ya',
    };
  }

  bool isHasilBerhasilTerhubung(HasilSegarkan hasil) {
    return hasil == HasilSegarkan.diperbarui ||
        hasil == HasilSegarkan.tidakAdaPerubahan;
  }

  String teksSejak(DateTime waktu) {
    return ubahJarakWaktuJadiTeks(DateTime.now().difference(waktu))
        .toLowerCase();
  }

  String? teksTerakhirDiperbarui(HomeProvider home) {
    DateTime? waktuTerakhir = home.waktuTerakhirDiperbarui;
    if (waktuTerakhir == null || home.isMemakaiDataCadangan) return null;
    return 'Diperbarui ${teksSejak(waktuTerakhir)} · tarik ke bawah untuk menyegarkan';
  }

  String teksSpandukBeranda(HomeProvider home) {
    String awalanPesan = home.isSedangOffline
        ? 'Kamu sedang offline.'
        : 'Server belum bisa dihubungi.';

    if (home.asalFeed == AsalFeed.contoh) {
      return '$awalanPesan Capy menampilkan lagu contoh dulu.';
    }

    DateTime? waktuDisimpan = home.waktuFeedDisimpan;
    if (waktuDisimpan == null) {
      return '$awalanPesan Ini berandamu yang terakhir tersimpan.';
    }
    return '$awalanPesan Ini berandamu dari ${teksSejak(waktuDisimpan)}.';
  }

  String teksDurasi(Duration durasi) {
    int menit = durasi.inMinutes;
    String detik = (durasi.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  Future<void> segarkanBeranda() async {
    HomeProvider home = context.read<HomeProvider>();
    HapticFeedback.mediumImpact();
    setState(() => isSedangTarikSegarkan = true);

    HasilSegarkan hasil = await home.segarkanBeranda();
    if (!mounted) return;
    setState(() => isSedangTarikSegarkan = false);

    tampilkanPesan(pesanDariHasilSegarkan(hasil, home));
  }

  Future<void> cobaLagiSaatAplikasiDibukaKembali() async {
    HomeProvider home = context.read<HomeProvider>();
    bool isPerluDicobaLagi =
        home.isSudahPernahDimuat &&
        home.isMemakaiDataCadangan &&
        !home.isSedangMemuat;
    if (!isPerluDicobaLagi) return;

    HasilSegarkan hasil = await home.segarkanBeranda(isAbaikanJeda: true);
    if (!mounted) return;

    if (isHasilBerhasilTerhubung(hasil)) {
      tampilkanPesan('Kamu kembali online, beranda sudah diperbarui');
    }
  }

  Future<void> cobaHubungkanLagi() async {
    HomeProvider home = context.read<HomeProvider>();
    HasilSegarkan hasil = await home.segarkanBeranda(isAbaikanJeda: true);
    if (!mounted) return;

    if (isHasilBerhasilTerhubung(hasil)) {
      tampilkanPesan('Berhasil terhubung, beranda sudah diperbarui');
    } else {
      tampilkanPesan(pesanDariHasilSegarkan(hasil, home));
    }
  }

  void ingatkanJikaSedangOffline() {
    if (!context.read<HomeProvider>().isSedangOffline) return;
    tampilkanPesan('Kamu sedang offline, lagu mungkin gagal diputar');
  }

  void putarLangsungDariBeranda(
    List<Lagu> antrian,
    int indexLagu,
    String namaAntrian,
  ) {
    if (indexLagu < 0 || indexLagu >= antrian.length) return;

    AudioProvider audio = context.read<AudioProvider>();
    if (!audio.mintaIzinPemutaran()) return;

    StatusPemutarBeranda statusSekarang = StatusPemutarBeranda.dariPemutar(
      audio,
    );
    if (statusSekarang.isLaguIniAktif(antrian[indexLagu])) {
      if (!statusSekarang.isAdaYangBerjalan) audio.putar();
      PlayerScreen.bukaLayarPenuh(context);
      return;
    }

    ingatkanJikaSedangOffline();
    audio.mulaiAntrian(
      antrian,
      indexMulai: indexLagu,
      namaAntrian: namaAntrian,
    );
  }

  void tekanTombolPutarLanjutan(Lagu laguLanjutan) {
    AudioProvider audio = context.read<AudioProvider>();
    if (!audio.mintaIzinPemutaran()) return;

    if (StatusPemutarBeranda.dariPemutar(audio).isLaguIniAktif(laguLanjutan)) {
      audio.togglePutarJeda();
      return;
    }

    ingatkanJikaSedangOffline();
    audio.mulaiAntrian(ambilAntrianRiwayat(), namaAntrian: namaAntrianRiwayat);
  }

  void putarRacikan(RacikanUntukmu racikan) {
    List<Lagu> isiRacikan = racikan.playlist.daftarLagu;
    if (isiRacikan.isEmpty) {
      tampilkanPesan('Racikan ini belum punya lagu');
      return;
    }

    AudioProvider audio = context.read<AudioProvider>();
    if (!audio.mintaIzinPemutaran()) return;

    if (StatusPemutarBeranda.dariPemutar(audio).isRacikanIniAktif(racikan)) {
      audio.togglePutarJeda();
      return;
    }

    ingatkanJikaSedangOffline();
    audio.mulaiAntrian(isiRacikan, namaAntrian: racikan.playlist.nama);
  }

  List<Lagu> ambilAntrianRiwayat() {
    return context
        .read<HomeProvider>()
        .riwayatTerakhirDiputar
        .map((riwayat) => riwayat.lagu)
        .toList();
  }

  void putarDariRiwayat(int indexRiwayat) {
    putarLangsungDariBeranda(
      ambilAntrianRiwayat(),
      indexRiwayat,
      namaAntrianRiwayat,
    );
  }

  void putarLaguTemuan(int indexLagu) {
    List<Lagu> antrianTemuan = List.of(
      context.read<HomeProvider>().laguBelumPernahDidengar,
    );
    putarLangsungDariBeranda(antrianTemuan, indexLagu, namaAntrianTemuan);
  }

  Future<void> bukaPengaturanGenre() async {
    bool? isPreferensiDisimpan = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PreferensiGenreScreen()),
    );

    if (!mounted || isPreferensiDisimpan != true) return;
    tampilkanPesan('Genre favoritmu sudah disimpan, racikan ikut diperbarui');
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
    AuthProvider? authProvider = context.watch<AuthProvider?>();
    String namaSapaan = (authProvider?.isSudahMasuk ?? false)
        ? authProvider!.namaTampilan
        : widget.namaPengguna;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: SapaanBeranda(namaPengguna: namaSapaan),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: WarnaCapify.krem),
            onPressed: () => tampilkanPesan('Fitur notifikasi segera hadir'),
          ),
          const TombolAvatarProfil(),
          const SizedBox(width: 8),
        ],
      ),
      body: buildIsiBeranda(home),
    );
  }

  Widget bungkusDenganPenyegar(Widget isiYangBisaDitarik) {
    return RefreshIndicator(
      color: WarnaCapify.coklatGelap,
      backgroundColor: WarnaCapify.krem,
      onRefresh: segarkanBeranda,
      child: isiYangBisaDitarik,
    );
  }

  StatusPemutarBeranda bacaStatusPemutar() {
    return StatusPemutarBeranda(
      kunciLaguAktif: context.select<AudioProvider, String?>((audio) {
        Lagu? laguDiPemutar = audio.laguSekarang;
        return laguDiPemutar == null ? null : kunciUnikLagu(laguDiPemutar);
      }),
      namaAntrianAktif: context.select<AudioProvider, String>(
        (audio) => audio.namaAntrian,
      ),
      isSedangDiputar: context.select<AudioProvider, bool>(
        (audio) => audio.isLaguSedangDiputar,
      ),
      isSedangMemuat: context.select<AudioProvider, bool>(
        (audio) => audio.isSedangMemuat,
      ),
    );
  }

  Widget buildIsiBeranda(HomeProvider home) {
    String? pesanGagal = home.pesanGagal;

    if (!home.isSudahPernahDimuat && pesanGagal != null) {
      return bungkusDenganPenyegar(
        TampilanBerandaGagal(
          pesanGagal: pesanGagal,
          onCobaLagi: home.muatIsiBeranda,
        ),
      );
    }

    if (!home.isSudahPernahDimuat) {
      return KerangkaBerandaMemuat(isKoneksiLambat: home.isMemuatTerlaluLama);
    }

    bool isTampilkanGarisProgres =
        home.isSedangMenyegarkan && !isSedangTarikSegarkan;
    String? keteranganDiperbarui = teksTerakhirDiperbarui(home);
    StatusPemutarBeranda statusPemutar = bacaStatusPemutar();

    return Column(
      children: [
        SizedBox(
          height: 3,
          child: isTampilkanGarisProgres
              ? const LinearProgressIndicator(
                  color: WarnaCapify.krem,
                  backgroundColor: WarnaCapify.coklatTua,
                )
              : null,
        ),
        Expanded(
          child: bungkusDenganPenyegar(
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 9, bottom: 32),
              children: [
                if (home.isMemakaiDataCadangan)
                  SpandukDataCadangan(
                    isSedangMencoba: home.isSedangMenyegarkan,
                    onCobaLagi: cobaHubungkanLagi,
                    pesanKhusus: teksSpandukBeranda(home),
                    ikon: home.isSedangOffline
                        ? Icons.wifi_off_rounded
                        : Icons.cloud_off_rounded,
                  ),
                if (keteranganDiperbarui != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      keteranganDiperbarui,
                      style: GayaTeksBeranda.labelKecil,
                    ),
                  ),
                ...buildBagianTerakhirDiputar(home, statusPemutar),
                const SizedBox(height: 28),
                ...buildBagianRacikanUntukmu(home, statusPemutar),
                const SizedBox(height: 28),
                ...buildBagianLaguTemuan(home, statusPemutar),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> buildBagianTerakhirDiputar(
    HomeProvider home,
    StatusPemutarBeranda statusPemutar,
  ) {
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
        isSedangDiputar: statusPemutar.isLaguIniDiputar(
          laguUntukDilanjutkan.lagu,
        ),
        isSedangDisiapkan: statusPemutar.isLaguIniDisiapkan(
          laguUntukDilanjutkan.lagu,
        ),
        onTekan: () => putarDariRiwayat(0),
        onTekanTombolPutar: () =>
            tekanTombolPutarLanjutan(laguUntukDilanjutkan.lagu),
      ),
      if (jumlahSisaRiwayat > 0) ...[
        const SizedBox(height: 28),
        const JudulBagianBeranda(judul: 'Terakhir diputar'),
        RakGeserHorizontal(
          tinggiGambar: 140,
          tinggiTeks: 82,
          jumlahItem: jumlahSisaRiwayat,
          pembuatItem: (context, index) {
            int indexAsli = index + 1;
            RiwayatPutar riwayat = semuaRiwayat[indexAsli];
            return KartuLaguKecil(
              lagu: riwayat.lagu,
              keterangan: riwayat.teksWaktuDiputar,
              isSedangDiputar: statusPemutar.isLaguIniDiputar(riwayat.lagu),
              isSedangDisiapkan: statusPemutar.isLaguIniDisiapkan(riwayat.lagu),
              onTekan: () => putarDariRiwayat(indexAsli),
            );
          },
        ),
      ],
    ];
  }

  List<Widget> buildBagianRacikanUntukmu(
    HomeProvider home,
    StatusPemutarBeranda statusPemutar,
  ) {
    List<RacikanUntukmu> daftarRacikan = home.daftarRacikanUntukmu;
    bool isSudahPilihGenre = home.isSudahPilihGenre;

    return [
      JudulBagianBeranda(
        judul: 'Racikan untukmu',
        keterangan: isSudahPilihGenre
            ? 'Dimulai dari genre favoritmu'
            : 'Diurutkan dari genre yang paling sering kamu putar',
        tombolAksi: TextButton(
          onPressed: bukaPengaturanGenre,
          child: Text(
            isSudahPilihGenre ? 'Atur genre' : 'Pilih genre',
            style: GayaTeksBeranda.tombolAksiBagian,
          ),
        ),
      ),
      if (daftarRacikan.isEmpty)
        const KotakBelumAdaIsi(
          ikon: Icons.auto_awesome_outlined,
          pesan: 'Capy belum punya racikan buat kamu',
        )
      else
        RakGeserHorizontal(
          tinggiGambar: 150,
          tinggiTeks: 60,
          jumlahItem: daftarRacikan.length,
          pembuatItem: (context, index) {
            RacikanUntukmu racikan = daftarRacikan[index];
            return KartuRacikanUntukmu(
              racikan: racikan,
              isSedangDiputar: statusPemutar.isRacikanIniDiputar(racikan),
              onTekan: () => bukaRacikan(racikan),
              onTekanPutar: () => putarRacikan(racikan),
            );
          },
        ),
    ];
  }

  List<Widget> buildBagianLaguTemuan(
    HomeProvider home,
    StatusPemutarBeranda statusPemutar,
  ) {
    List<Lagu> laguTemuan = home.laguBelumPernahDidengar;

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
          tinggiGambar: 140,
          tinggiTeks: 82,
          jumlahItem: laguTemuan.length,
          pembuatItem: (context, index) {
            Lagu lagu = laguTemuan[index];
            return KartuLaguKecil(
              lagu: lagu,
              keterangan: teksDurasi(lagu.durasi),
              isSedangDiputar: statusPemutar.isLaguIniDiputar(lagu),
              isSedangDisiapkan: statusPemutar.isLaguIniDisiapkan(lagu),
              onTekan: () => putarLaguTemuan(index),
            );
          },
        ),
    ];
  }
}

class StatusPemutarBeranda {
  final String? kunciLaguAktif;
  final String namaAntrianAktif;
  final bool isSedangDiputar;
  final bool isSedangMemuat;

  const StatusPemutarBeranda({
    required this.kunciLaguAktif,
    required this.namaAntrianAktif,
    required this.isSedangDiputar,
    required this.isSedangMemuat,
  });

  factory StatusPemutarBeranda.dariPemutar(AudioProvider audio) {
    Lagu? laguDiPemutar = audio.laguSekarang;
    return StatusPemutarBeranda(
      kunciLaguAktif: laguDiPemutar == null
          ? null
          : kunciUnikLagu(laguDiPemutar),
      namaAntrianAktif: audio.namaAntrian,
      isSedangDiputar: audio.isLaguSedangDiputar,
      isSedangMemuat: audio.isSedangMemuat,
    );
  }

  bool get isAdaYangBerjalan => isSedangDiputar || isSedangMemuat;

  bool isLaguIniAktif(Lagu lagu) {
    return kunciLaguAktif != null && kunciLaguAktif == kunciUnikLagu(lagu);
  }

  bool isLaguIniDiputar(Lagu lagu) {
    return isLaguIniAktif(lagu) && isSedangDiputar && !isSedangMemuat;
  }

  bool isLaguIniDisiapkan(Lagu lagu) {
    return isLaguIniAktif(lagu) && isSedangMemuat;
  }

  bool isRacikanIniAktif(RacikanUntukmu racikan) {
    if (namaAntrianAktif != racikan.playlist.nama) return false;
    return racikan.playlist.daftarLagu.any(isLaguIniAktif);
  }

  bool isRacikanIniDiputar(RacikanUntukmu racikan) {
    return isAdaYangBerjalan && isRacikanIniAktif(racikan);
  }
}
