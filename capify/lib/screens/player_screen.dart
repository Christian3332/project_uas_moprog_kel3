import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lagu.dart';
import '../providers/audio_provider.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';
import '../widgets/kontrol_player.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static void bukaLayarPenuh(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const PlayerScreen(),
      ),
    );
  }

  void tampilkanPesan(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(pesan), duration: const Duration(seconds: 2)),
      );
  }

  void tekanTombolNext(BuildContext context, AudioProvider audio) {
    bool isBerhasilPindah = audio.laguBerikutnya();
    if (!isBerhasilPindah) {
      tampilkanPesan(context, 'Ini sudah lagu terakhir di antrian');
    }
  }

  @override
  Widget build(BuildContext context) {
    AudioProvider audio = context.watch<AudioProvider>();
    Lagu? lagu = audio.laguSekarang;

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
        appBar: buildAppBarPlayer(context, audio.namaAntrian),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: lagu == null
                ? buildAntrianKosong()
                : buildIsiPlayer(context, audio, lagu),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget buildAppBarPlayer(
    BuildContext context,
    String namaAntrian,
  ) {
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
            namaAntrian,
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
          onPressed: () =>
              tampilkanPesan(context, 'Menu lainnya belum tersedia'),
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

  Widget buildIsiPlayer(BuildContext context, AudioProvider audio, Lagu lagu) {
    bool isDisukai = audio.isLaguSekarangDisukai;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AnimatedScale(
              scale: audio.isLaguSedangDiputar ? 1 : 0.88,
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
              onPressed: audio.toggleSukaiLaguSekarang,
              tooltip: isDisukai ? 'Hapus dari disukai' : 'Sukai lagu ini',
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
          posisiSekarang: audio.posisiSekarang,
          durasiLagu: lagu.durasi,
          onGeser: (detikTujuan) =>
              audio.geserKe(Duration(seconds: detikTujuan.round())),
        ),
        const SizedBox(height: 12),
        TombolKontrolPlayer(
          isLaguSedangDiputar: audio.isLaguSedangDiputar,
          isSedangMemuat: audio.isSedangMemuat,
          isAcak: audio.isAcak,
          modeUlang: audio.modeUlang,
          onTekanPlay: audio.togglePutarJeda,
          onTekanPrevious: audio.laguSebelumnya,
          onTekanNext: () => tekanTombolNext(context, audio),
          onTekanAcak: audio.toggleAcak,
          onTekanUlang: audio.gantiModeUlang,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
