import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lagu.dart';
import '../models/playlist.dart';
import '../providers/audio_provider.dart';
import '../providers/playlist_provider.dart';
import '../utils/format_waktu.dart';
import '../utils/kunci_lagu.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';

class DetailPlaylistScreen extends StatefulWidget {
  final Playlist playlist;

  const DetailPlaylistScreen({super.key, required this.playlist});

  @override
  State<DetailPlaylistScreen> createState() => _DetailPlaylistScreenState();
}

class _DetailPlaylistScreenState extends State<DetailPlaylistScreen> {
  String ringkasanIsiPlaylist(Playlist playlist) {
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

  void tampilkanPesanSingkat(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  void putarLagu(Playlist playlist, int urutan) {
    AudioProvider audio = context.read<AudioProvider>();
    if (!audio.mintaIzinPemutaran()) return;

    audio.mulaiAntrian(
      playlist.daftarLagu,
      indexMulai: urutan,
      namaAntrian: playlist.nama,
    );
  }

  Future<void> hapusLagu(Playlist playlist, Lagu lagu) async {
    String? pesanGagal = await context
        .read<PlaylistProvider>()
        .hapusLaguDariPlaylist(idPlaylist: playlist.id, lagu: lagu);
    if (!mounted) return;

    tampilkanPesanSingkat(
      pesanGagal ?? '"${lagu.judul}" dihapus dari ${playlist.nama}',
    );
  }

  @override
  Widget build(BuildContext context) {
    Playlist? playlistDiKoleksi = context
        .watch<PlaylistProvider>()
        .cariPlaylist(widget.playlist.id);
    bool isPlaylistMilikPengguna = playlistDiKoleksi != null;
    Playlist playlist = playlistDiKoleksi ?? widget.playlist;
    bool isPlaylistKosong = playlist.daftarLagu.isEmpty;

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
              ringkasanIsiPlaylist(playlist),
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
                    : () => putarLagu(playlist, 0),
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
                  isSedangDiputar:
                      isAudioSedangDiputar &&
                      kunciLaguAktif ==
                          kunciUnikLagu(playlist.daftarLagu[urutan]),
                  onDitekan: () => putarLagu(playlist, urutan),
                  onTekanHapus: isPlaylistMilikPengguna
                      ? () => hapusLagu(playlist, playlist.daftarLagu[urutan])
                      : null,
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
  final bool isSedangDiputar;
  final VoidCallback onDitekan;
  final VoidCallback? onTekanHapus;

  const BarisLaguTracklist({
    super.key,
    required this.nomorUrut,
    required this.lagu,
    required this.isSedangDiputar,
    required this.onDitekan,
    this.onTekanHapus,
  });

  @override
  Widget build(BuildContext context) {
    Color warnaJudul = isSedangDiputar ? WarnaCapify.krem : WarnaCapify.putih;
    VoidCallback? aksiHapus = onTekanHapus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSedangDiputar
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
                    child: isSedangDiputar
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
                  FormatWaktu.durasiLagu(lagu.durasi),
                  style: const TextStyle(fontSize: 12, color: WarnaCapify.krem),
                ),
                if (aksiHapus != null)
                  PopupMenuButton<String>(
                    tooltip: 'Pilihan lain',
                    color: WarnaCapify.coklatTua,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: WarnaCapify.krem,
                    ),
                    onSelected: (pilihan) => aksiHapus(),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'hapus',
                        child: Text(
                          'Hapus dari playlist',
                          style: TextStyle(color: WarnaCapify.putih),
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
