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

  Future<void> segarkanBeranda() async {
    HomeProvider home = context.read<HomeProvider>();
    HapticFeedback.mediumImpact();
    setState(() => isSedangTarikSegarkan = true);

    HasilSegarkan hasil = await home.segarkanBeranda();
    if (!mounted) return;
    setState(() => isSedangTarikSegarkan = false);

    tampilkanPesan(pesanDariHasilSegarkan(hasil, home));
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

  String? teksTerakhirDiperbarui(HomeProvider home) {
    DateTime? waktuTerakhir = home.waktuTerakhirDiperbarui;
    if (waktuTerakhir == null || home.isMemakaiDataCadangan) return null;

    String sejakKapan = ubahJarakWaktuJadiTeks(
      DateTime.now().difference(waktuTerakhir),
    ).toLowerCase();
    return 'Diperbarui $sejakKapan · tarik ke bawah untuk menyegarkan';
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

    String sejakKapan = ubahJarakWaktuJadiTeks(
      DateTime.now().difference(waktuDisimpan),
    ).toLowerCase();
    return '$awalanPesan Ini berandamu dari $sejakKapan.';
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

    AudioProvider audio = context.read<AudioProvider>();
    if (isLaguIniYangAktif(audio, antrian[indexLagu])) {
      if (!audio.isLaguSedangDiputar) audio.putar();
    } else {
      audio.mulaiAntrian(
        antrian,
        indexMulai: indexLagu,
        namaAntrian: namaAntrian,
      );
    }
    PlayerScreen.bukaLayarPenuh(context);
  }

  bool isLaguIniYangAktif(AudioProvider audio, Lagu lagu) {
    Lagu? laguDiPemutar = audio.laguSekarang;
    if (laguDiPemutar == null) return false;

    HomeProvider home = context.read<HomeProvider>();
    return home.kunciLagu(laguDiPemutar) == home.kunciLagu(lagu);
  }

  void tekanTombolPutarLanjutan(Lagu laguLanjutan) {
    AudioProvider audio = context.read<AudioProvider>();
    if (isLaguIniYangAktif(audio, laguLanjutan)) {
      audio.togglePutarJeda();
      return;
    }

    List<Lagu> antrianRiwayat = context
        .read<HomeProvider>()
        .riwayatTerakhirDiputar
        .map((riwayat) => riwayat.lagu)
        .toList();
    audio.mulaiAntrian(antrianRiwayat, namaAntrian: 'Terakhir Diputar');
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
              namaSapaan,
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
          const TombolAvatarProfil(),
          const SizedBox(width: 8),
        ],
      ),
      body: buildIsiBeranda(home),
    );
  }

  Widget buildIsiBeranda(HomeProvider home) {
    String? pesanGagal = home.pesanGagal;

    if (!home.isSudahPernahDimuat && pesanGagal != null) {
      return RefreshIndicator(
        color: WarnaCapify.coklatGelap,
        backgroundColor: WarnaCapify.krem,
        onRefresh: segarkanBeranda,
        child: LayoutBuilder(
          builder: (context, ukuranLayar) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: ukuranLayar.maxHeight),
                child: Center(
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
                        const SizedBox(height: 8),
                        Text(
                          'atau tarik layar ke bawah',
                          style: TextStyle(
                            color: WarnaCapify.krem.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    if (!home.isSudahPernahDimuat) {
      return KerangkaBerandaMemuat(isKoneksiLambat: home.isMemuatTerlaluLama);
    }

    bool isTampilkanGarisProgres =
        home.isSedangMenyegarkan && !isSedangTarikSegarkan;
    String? keteranganDiperbarui = teksTerakhirDiperbarui(home);

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
          child: RefreshIndicator(
            color: WarnaCapify.coklatGelap,
            backgroundColor: WarnaCapify.krem,
            onRefresh: segarkanBeranda,
            child: ListView(
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
                      style: TextStyle(
                        color: WarnaCapify.krem.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ...buildBagianTerakhirDiputar(home),
                const SizedBox(height: 28),
                ...buildBagianRacikanUntukmu(
                  home.daftarRacikanUntukmu,
                  home.isSudahPilihGenre,
                ),
                const SizedBox(height: 28),
                ...buildBagianLaguTemuan(home.laguBelumPernahDidengar),
              ],
            ),
          ),
        ),
      ],
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
    String kunciLaguLanjutan = home.kunciLagu(laguUntukDilanjutkan.lagu);

    bool isLaguLanjutanAktif = context.select<AudioProvider, bool>((audio) {
      Lagu? laguDiPemutar = audio.laguSekarang;
      return laguDiPemutar != null &&
          home.kunciLagu(laguDiPemutar) == kunciLaguLanjutan;
    });
    bool isPemutarSedangJalan = context.select<AudioProvider, bool>(
      (audio) => audio.isLaguSedangDiputar,
    );
    bool isPemutarSedangMenyiapkan = context.select<AudioProvider, bool>(
      (audio) => audio.isSedangMemuat,
    );

    return [
      KartuLanjutDengerin(
        riwayat: laguUntukDilanjutkan,
        isSedangDiputar: isLaguLanjutanAktif && isPemutarSedangJalan,
        isSedangDisiapkan: isLaguLanjutanAktif && isPemutarSedangMenyiapkan,
        onTekan: () => putarDariRiwayat(0),
        onTekanTombolPutar: () =>
            tekanTombolPutarLanjutan(laguUntukDilanjutkan.lagu),
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

  List<Widget> buildBagianRacikanUntukmu(
    List<RacikanUntukmu> daftarRacikan,
    bool isSudahPilihGenre,
  ) {
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
            style: const TextStyle(color: WarnaCapify.krem),
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
