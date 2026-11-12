import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/lagu.dart';
import '../utils/warna_capify.dart';

enum ModeUlang { mati, semua, satu }

class PlayerScreen extends StatefulWidget {
  final List<Lagu> antrianLagu;
  final int indexMulai;

  const PlayerScreen({
    super.key,
    required this.antrianLagu,
    this.indexMulai = 0,
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
        SnackBar(
          content: Text(pesan),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> tekanTombolPlay() async {
    if (laguSekarang == null || isSedangMemuat) return;

    if (isLaguSedangDiputar) {
      timerPemutar?.cancel();
      setState(() => isLaguSedangDiputar = false);
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
  }

  void geserSeekbar(double detikTujuan) {
    setState(() => posisiSekarang = Duration(seconds: detikTujuan.round()));
  }

  void gantiModeUlang() {
    int indexModeBaru = (modeUlang.index + 1) % ModeUlang.values.length;
    setState(() => modeUlang = ModeUlang.values[indexModeBaru]);
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

  String formatWaktu(Duration waktu) {
    int menit = waktu.inMinutes;
    int detik = waktu.inSeconds % 60;
    return '$menit:${detik.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Lagu? lagu = laguSekarang;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WarnaCapify.coklatTua, WarnaCapify.hitam],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                buildBarAtas(),
                Expanded(
                  child: lagu == null
                      ? buildAntrianKosong()
                      : buildIsiPlayer(lagu),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBarAtas() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            color: WarnaCapify.putih,
          ),
          const Expanded(
            child: Text(
              'Sedang Diputar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WarnaCapify.putih,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => tampilkanPesan('Menu lainnya belum tersedia'),
            icon: const Icon(Icons.more_vert),
            color: WarnaCapify.putih,
          ),
        ],
      ),
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
    double durasiDalamDetik = lagu.durasi.inSeconds.toDouble();
    double maksSlider = durasiDalamDetik > 0 ? durasiDalamDetik : 1;
    double posisiSlider =
        posisiSekarang.inSeconds.toDouble().clamp(0, maksSlider);
    bool isDisukai = indexLaguDisukai.contains(indexLaguSekarang);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: buildCoverLagu(lagu.urlCover),
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: WarnaCapify.krem,
            inactiveTrackColor: Colors.white24,
            thumbColor: WarnaCapify.krem,
            overlayColor: WarnaCapify.krem.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: posisiSlider,
            min: 0,
            max: maksSlider,
            onChanged: geserSeekbar,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatWaktu(posisiSekarang),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                formatWaktu(lagu.durasi),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        buildTombolKontrol(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget buildCoverLagu(String urlCover) {
    Widget coverCadangan = Container(
      color: WarnaCapify.coklatGelap,
      child: const Icon(
        Icons.music_note_rounded,
        size: 96,
        color: WarnaCapify.krem,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: urlCover.isEmpty
          ? coverCadangan
          : Image.network(
              urlCover,
              fit: BoxFit.cover,
              loadingBuilder: (context, gambar, progresLoading) {
                if (progresLoading == null) return gambar;
                return Container(
                  color: WarnaCapify.coklatGelap,
                  child: const Center(
                    child: CircularProgressIndicator(color: WarnaCapify.krem),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => coverCadangan,
            ),
    );
  }

  Widget buildTombolKontrol() {
    Color warnaAcak = isAcak ? WarnaCapify.krem : Colors.white54;
    Color warnaUlang =
        modeUlang == ModeUlang.mati ? Colors.white54 : WarnaCapify.krem;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => setState(() => isAcak = !isAcak),
          icon: Icon(Icons.shuffle_rounded, color: warnaAcak),
        ),
        IconButton(
          onPressed: tekanTombolPrevious,
          iconSize: 40,
          icon: const Icon(
            Icons.skip_previous_rounded,
            color: WarnaCapify.putih,
          ),
        ),
        GestureDetector(
          onTap: tekanTombolPlay,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: WarnaCapify.krem,
              shape: BoxShape.circle,
            ),
            child: isSedangMemuat
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: WarnaCapify.coklatGelap,
                    ),
                  )
                : Icon(
                    isLaguSedangDiputar
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 40,
                    color: WarnaCapify.coklatGelap,
                  ),
          ),
        ),
        IconButton(
          onPressed: pindahKeLaguBerikutnya,
          iconSize: 40,
          icon: const Icon(Icons.skip_next_rounded, color: WarnaCapify.putih),
        ),
        IconButton(
          onPressed: gantiModeUlang,
          icon: Icon(
            modeUlang == ModeUlang.satu
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: warnaUlang,
          ),
        ),
      ],
    );
  }
}
