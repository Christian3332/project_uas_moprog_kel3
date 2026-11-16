import 'package:flutter/material.dart';

import '../models/lagu.dart';
import '../models/playlist.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';

class DetailPlaylistScreen extends StatefulWidget {
  final Playlist playlist;

  const DetailPlaylistScreen({super.key, required this.playlist});

  @override
  State<DetailPlaylistScreen> createState() => _DetailPlaylistScreenState();
}

class _DetailPlaylistScreenState extends State<DetailPlaylistScreen> {
  int? urutanLaguDipilih;

  String ringkasanIsiPlaylist() {
    int jumlahLagu = widget.playlist.daftarLagu.length;
    if (jumlahLagu == 0) return 'Playlist • 0 lagu';

    Duration totalDurasi = Duration.zero;
    for (Lagu lagu in widget.playlist.daftarLagu) {
      totalDurasi += lagu.durasi;
    }

    int totalMenit = totalDurasi.inMinutes;
    int sisaDetik = totalDurasi.inSeconds % 60;
    return 'Playlist • $jumlahLagu lagu • $totalMenit mnt $sisaDetik dtk';
  }

  void tampilkanPesanSingkat(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  void pilihLaguDiTracklist(int urutan) {
    setState(() {
      if (urutanLaguDipilih == urutan) {
        urutanLaguDipilih = null;
      } else {
        urutanLaguDipilih = urutan;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Playlist playlist = widget.playlist;
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
            judulBagianTracklist(playlist.daftarLagu.length),
            const SizedBox(height: 8),
            if (isPlaylistKosong)
              kotakPlaylistMasihKosong()
            else
              for (
                int urutan = 0;
                urutan < playlist.daftarLagu.length;
                urutan++
              )
                BarisLaguTracklist(
                  nomorUrut: urutan + 1,
                  lagu: playlist.daftarLagu[urutan],
                  isSedangDipilih: urutanLaguDipilih == urutan,
                  onDitekan: () => pilihLaguDiTracklist(urutan),
                  onTekanPilihanLain: () => tampilkanPesanSingkat(
                    'Pilihan untuk ${playlist.daftarLagu[urutan].judul} segera hadir',
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget judulBagianTracklist(int jumlahLagu) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Daftar Lagu',
            style: TextStyle(
              fontSize: 18,
              color: WarnaCapify.putih,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '$jumlahLagu lagu',
          style: const TextStyle(
            color: WarnaCapify.krem,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
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
          Icon(Icons.playlist_add_rounded, size: 36, color: WarnaCapify.krem),
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

class BarisLaguTracklist extends StatelessWidget {
  final int nomorUrut;
  final Lagu lagu;
  final bool isSedangDipilih;
  final VoidCallback onDitekan;
  final VoidCallback onTekanPilihanLain;

  const BarisLaguTracklist({
    super.key,
    required this.nomorUrut,
    required this.lagu,
    required this.isSedangDipilih,
    required this.onDitekan,
    required this.onTekanPilihanLain,
  });

  String formatDurasiLagu(Duration durasi) {
    String menit = durasi.inMinutes.toString();
    String detik = (durasi.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  @override
  Widget build(BuildContext context) {
    Color warnaJudul = isSedangDipilih ? WarnaCapify.krem : WarnaCapify.putih;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSedangDipilih
            ? WarnaCapify.coklatTua.withValues(alpha: 0.6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onDitekan,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Center(
                    child: isSedangDipilih
                        ? const Icon(
                            Icons.graphic_eq_rounded,
                            size: 18,
                            color: WarnaCapify.krem,
                          )
                        : Text(
                            '$nomorUrut',
                            style: const TextStyle(
                              color: WarnaCapify.krem,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CoverAlbum(
                    urlCover: lagu.urlCover,
                    lengkungSudut: 6,
                    isPakaiBayangan: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lagu.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: warnaJudul,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lagu.penyanyi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: WarnaCapify.krem,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDurasiLagu(lagu.durasi),
                  style: const TextStyle(fontSize: 12, color: WarnaCapify.krem),
                ),
                IconButton(
                  tooltip: 'Pilihan lain',
                  onPressed: onTekanPilihanLain,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: WarnaCapify.krem,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
