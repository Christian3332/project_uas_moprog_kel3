import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/katalog_pencarian_dummy.dart';
import '../models/album.dart';
import '../models/lagu.dart';
import '../providers/audio_provider.dart';
import '../utils/kunci_lagu.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';
import 'detail_playlist_screen.dart';

class DetailAlbumScreen extends StatefulWidget {
  final Album album;

  const DetailAlbumScreen({super.key, required this.album});

  @override
  State<DetailAlbumScreen> createState() => _DetailAlbumScreenState();
}

class _DetailAlbumScreenState extends State<DetailAlbumScreen> {
  bool isAlbumDisukai = false;
  List<Lagu> laguDiAlbum = [];

  @override
  void initState() {
    super.initState();
    laguDiAlbum = ambilLaguDariAlbum(widget.album);
  }

  void tampilkanPesanSingkat(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  void gantiStatusSuka() {
    setState(() => isAlbumDisukai = !isAlbumDisukai);
    tampilkanPesanSingkat(
      isAlbumDisukai
          ? 'Album ditambahkan ke koleksi'
          : 'Album dihapus dari koleksi',
    );
  }

  void putarLagu(int urutan) {
    AudioProvider audio = context.read<AudioProvider>();
    if (!audio.mintaIzinPemutaran()) return;

    audio.mulaiAntrian(
      laguDiAlbum,
      indexMulai: urutan,
      namaAntrian: 'Album ${widget.album.judul}',
    );
  }

  @override
  Widget build(BuildContext context) {
    Album album = widget.album;
    bool isBelumAdaLagu = laguDiAlbum.isEmpty;

    String? kunciLaguAktif = context.select<AudioProvider, String?>((audio) {
      Lagu? laguDiPemutar = audio.laguSekarang;
      return laguDiPemutar == null ? null : kunciUnikLagu(laguDiPemutar);
    });
    bool isAudioSedangDiputar = context.select<AudioProvider, bool>(
      (audio) => audio.isLaguSedangDiputar,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        foregroundColor: WarnaCapify.putih,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Album',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CoverAlbum(urlCover: album.urlCover),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              album.judul,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                color: WarnaCapify.putih,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              album.penyanyi,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: WarnaCapify.krem),
            ),
            const SizedBox(height: 4),
            Text(
              'Album • ${album.jumlahLagu} lagu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.7),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 28,
                  onPressed: gantiStatusSuka,
                  icon: Icon(
                    isAlbumDisukai ? Icons.favorite : Icons.favorite_border,
                    color: isAlbumDisukai
                        ? WarnaCapify.krem
                        : WarnaCapify.putih,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: isBelumAdaLagu ? null : () => putarLagu(0),
                  style: FilledButton.styleFrom(
                    backgroundColor: WarnaCapify.krem,
                    foregroundColor: WarnaCapify.coklatGelap,
                    disabledBackgroundColor: WarnaCapify.coklatTua,
                    disabledForegroundColor: WarnaCapify.krem,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Putar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lagu yang tersedia',
                    style: TextStyle(
                      fontSize: 18,
                      color: WarnaCapify.putih,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${laguDiAlbum.length} dari ${album.jumlahLagu} lagu',
                  style: const TextStyle(
                    color: WarnaCapify.krem,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isBelumAdaLagu)
              kotakBelumAdaLagu()
            else
              for (int urutan = 0; urutan < laguDiAlbum.length; urutan++)
                BarisLaguTracklist(
                  nomorUrut: urutan + 1,
                  lagu: laguDiAlbum[urutan],
                  isSedangDiputar:
                      isAudioSedangDiputar &&
                      kunciLaguAktif == kunciUnikLagu(laguDiAlbum[urutan]),
                  onDitekan: () => putarLagu(urutan),
                ),
          ],
        ),
      ),
    );
  }

  Widget kotakBelumAdaLagu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: WarnaCapify.coklatTua),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.queue_music_rounded, size: 36, color: WarnaCapify.krem),
          SizedBox(height: 8),
          Text(
            'Belum ada lagu dari album ini di Capify',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WarnaCapify.krem,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
