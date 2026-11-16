import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/lagu.dart';
import '../models/mode_ulang.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';
import '../widgets/kontrol_player.dart';

class PlayerScreen extends StatefulWidget {
  final List<Lagu> antrianLagu;
  final int indexMulai;
  final String namaAntrian;
  final bool isMulaiDiputar;
  final void Function(int indexLagu, bool isDiputar)? onStatusPemutaranBerubah;

  const PlayerScreen({
    super.key,
    required this.antrianLagu,
    this.indexMulai = 0,
    this.namaAntrian = 'Lagu Pilihanmu',
    this.isMulaiDiputar = false,
    this.onStatusPemutaranBerubah,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int indexLaguSekarang = 0;
  bool isLaguSedangDiputar = false;
  bool isSedangMemuat = false;
  bool isAcak = false;
  ModeUlang modeUlang = ModeUlang.mati;
  Duration posisiSekarang = Duration.zero;
  Timer? timerPemutar;
  final Set<int> indexLaguDisukai = {};

  @override
  void initState() {
    super.initState();
    bool indexMulaiValid =
        widget.indexMulai >= 0 && widget.indexMulai < widget.antrianLagu.length;
    if (indexMulaiValid) {
      indexLaguSekarang = widget.indexMulai;
    }
    if (widget.isMulaiDiputar && widget.antrianLagu.isNotEmpty) {
      isLaguSedangDiputar = true;
      mulaiHitungWaktu();
    }
  }

  void kabariStatusPemutaran() {
    widget.onStatusPemutaranBerubah?.call(
      indexLaguSekarang,
      isLaguSedangDiputar,
    );
  }

  @override
  void dispose() {
    timerPemutar?.cancel();
    super.dispose();
  }

  Lagu? get laguSekarang {
    if (widget.antrianLagu.isEmpty) return null;
    return widget.antrianLagu[indexLaguSekarang];
  }

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(pesan), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> tekanTombolPlay() async {
    if (laguSekarang == null || isSedangMemuat) return;

    if (isLaguSedangDiputar) {
      timerPemutar?.cancel();
      setState(() => isLaguSedangDiputar = false);
      kabariStatusPemutaran();
      return;
    }

    setState(() => isSedangMemuat = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      isSedangMemuat = false;
      isLaguSedangDiputar = true;
    });
    mulaiHitungWaktu();
    kabariStatusPemutaran();
  }

  void mulaiHitungWaktu() {
    timerPemutar?.cancel();
    timerPemutar = Timer.periodic(const Duration(seconds: 1), (_) {
      Lagu? lagu = laguSekarang;
      if (lagu == null) return;

      Duration posisiBerikutnya = posisiSekarang + const Duration(seconds: 1);
      if (posisiBerikutnya >= lagu.durasi) {
        laguSudahHabis();
        return;
      }
      setState(() => posisiSekarang = posisiBerikutnya);
    });
  }

  void laguSudahHabis() {
    if (modeUlang == ModeUlang.satu) {
      setState(() => posisiSekarang = Duration.zero);
      return;
    }
    pindahKeLaguBerikutnya();
  }

  int? cariIndexBerikutnya() {
    int jumlahLagu = widget.antrianLagu.length;
    if (jumlahLagu == 0) return null;

    if (isAcak && jumlahLagu > 1) {
      int indexAcak = indexLaguSekarang;
      while (indexAcak == indexLaguSekarang) {
        indexAcak = Random().nextInt(jumlahLagu);
      }
      return indexAcak;
    }

    if (indexLaguSekarang + 1 < jumlahLagu) return indexLaguSekarang + 1;
    if (modeUlang == ModeUlang.semua) return 0;
    return null;
  }

  void pindahKeLaguBerikutnya() {
    if (laguSekarang == null) return;

    int? indexBerikutnya = cariIndexBerikutnya();
    if (indexBerikutnya == null) {
      timerPemutar?.cancel();
      setState(() {
        isLaguSedangDiputar = false;
        posisiSekarang = Duration.zero;
      });
      kabariStatusPemutaran();
      tampilkanPesan('Ini sudah lagu terakhir di antrian');
      return;
    }
    gantiLagu(indexBerikutnya);
  }

  void tekanTombolPrevious() {
    if (laguSekarang == null) return;

    bool sudahLewatTigaDetik = posisiSekarang.inSeconds > 3;
    if (sudahLewatTigaDetik || indexLaguSekarang == 0) {
      setState(() => posisiSekarang = Duration.zero);
      return;
    }
    gantiLagu(indexLaguSekarang - 1);
  }

  void gantiLagu(int indexBaru) {
    setState(() {
      indexLaguSekarang = indexBaru;
      posisiSekarang = Duration.zero;
    });
    kabariStatusPemutaran();
  }

  void geserSeekbar(double detikTujuan) {
    setState(() => posisiSekarang = Duration(seconds: detikTujuan.round()));
  }

  void gantiModeUlang() {
    int indexModeBaru = (modeUlang.index + 1) % ModeUlang.values.length;
    setState(() => modeUlang = ModeUlang.values[indexModeBaru]);
  }

  void toggleAcak() {
    setState(() => isAcak = !isAcak);
  }

  void toggleSukai() {
    setState(() {
      if (indexLaguDisukai.contains(indexLaguSekarang)) {
        indexLaguDisukai.remove(indexLaguSekarang);
      } else {
        indexLaguDisukai.add(indexLaguSekarang);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Lagu? lagu = laguSekarang;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WarnaCapify.coklatTua, WarnaCapify.hitam],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildAppBarPlayer(),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: lagu == null ? buildAntrianKosong() : buildIsiPlayer(lagu),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget buildAppBarPlayer() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 32,
          color: WarnaCapify.putih,
        ),
      ),
      title: Column(
        children: [
          const Text(
            'SEDANG DIPUTAR DARI',
            style: TextStyle(
              color: WarnaCapify.krem,
              fontSize: 11,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.namaAntrian,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WarnaCapify.putih,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => tampilkanPesan('Menu lainnya belum tersedia'),
          icon: const Icon(Icons.more_vert, color: WarnaCapify.putih),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget buildAntrianKosong() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_off_rounded, size: 72, color: WarnaCapify.krem),
          SizedBox(height: 16),
          Text(
            'Belum ada lagu di antrian',
            style: TextStyle(
              color: WarnaCapify.putih,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pilih lagu dari Home atau Cari dulu ya',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget buildIsiPlayer(Lagu lagu) {
    bool isDisukai = indexLaguDisukai.contains(indexLaguSekarang);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AnimatedScale(
              scale: isLaguSedangDiputar ? 1 : 0.88,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              child: AspectRatio(
                aspectRatio: 1,
                child: CoverAlbum(urlCover: lagu.urlCover),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lagu.judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WarnaCapify.putih,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lagu.penyanyi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: toggleSukai,
              icon: Icon(
                isDisukai ? Icons.favorite : Icons.favorite_border,
                color: isDisukai ? WarnaCapify.krem : WarnaCapify.putih,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SeekbarPlayer(
          posisiSekarang: posisiSekarang,
          durasiLagu: lagu.durasi,
          onGeser: geserSeekbar,
        ),
        const SizedBox(height: 12),
        TombolKontrolPlayer(
          isLaguSedangDiputar: isLaguSedangDiputar,
          isSedangMemuat: isSedangMemuat,
          isAcak: isAcak,
          modeUlang: modeUlang,
          onTekanPlay: tekanTombolPlay,
          onTekanPrevious: tekanTombolPrevious,
          onTekanNext: pindahKeLaguBerikutnya,
          onTekanAcak: toggleAcak,
          onTekanUlang: gantiModeUlang,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
