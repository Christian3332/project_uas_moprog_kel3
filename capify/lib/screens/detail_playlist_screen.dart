import 'package:flutter/material.dart';

import '../models/lagu.dart';
import '../models/playlist.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';

class DetailPlaylistScreen extends StatelessWidget {
  final Playlist playlist;

  const DetailPlaylistScreen({super.key, required this.playlist});

  String formatDurasiLagu(Duration durasi) {
    String menit = durasi.inMinutes.toString();
    String detik = (durasi.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  String ringkasanIsiPlaylist() {
    int jumlahLagu = playlist.daftarLagu.length;
    if (jumlahLagu == 0) return 'Playlist • 0 lagu';

    Duration totalDurasi = Duration.zero;
    for (Lagu lagu in playlist.daftarLagu) {
      totalDurasi += lagu.durasi;
    }

    int totalMenit = totalDurasi.inMinutes;
    int sisaDetik = totalDurasi.inSeconds % 60;
    return 'Playlist • $jumlahLagu lagu • $totalMenit mnt $sisaDetik dtk';
  }

  void tampilkanPesanSingkat(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    bool isPlaylistKosong = playlist.daftarLagu.isEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        foregroundColor: WarnaCapify.putih,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Playlist',
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
                child: CoverAlbum(urlCover: playlist.urlCoverPlaylist),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              playlist.nama,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                color: WarnaCapify.putih,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              playlist.deskripsi,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: WarnaCapify.krem),
            ),
            const SizedBox(height: 4),
            Text(
              ringkasanIsiPlaylist(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.7),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: isPlaylistKosong
                    ? null
                    : () => tampilkanPesanSingkat(
                          context,
                          'Pemutaran playlist segera hadir',
                        ),
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
            ),
            const SizedBox(height: 28),
            if (isPlaylistKosong)
              kotakPlaylistMasihKosong()
            else
              ...playlist.daftarLagu.map((lagu) => barisLaguPlaylist(lagu)),
          ],
        ),
      ),
    );
  }

  Widget barisLaguPlaylist(Lagu lagu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(
          width: 48,
          height: 48,
          child: CoverAlbum(
            urlCover: lagu.urlCover,
            lengkungSudut: 8,
            isPakaiBayangan: false,
          ),
        ),
        title: Text(
          lagu.judul,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: WarnaCapify.putih,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          lagu.penyanyi,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: WarnaCapify.krem),
        ),
        trailing: Text(
          formatDurasiLagu(lagu.durasi),
          style: const TextStyle(color: WarnaCapify.krem),
        ),
      ),
    );
  }

  Widget kotakPlaylistMasihKosong() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: WarnaCapify.coklatTua),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.playlist_add_rounded,
            size: 36,
            color: WarnaCapify.krem,
          ),
          SizedBox(height: 8),
          Text(
            'Playlist ini masih kosong, belum ada lagu yang ditambahkan',
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
