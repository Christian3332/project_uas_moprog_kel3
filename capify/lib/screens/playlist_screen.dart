import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/album.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';
import 'detail_playlist_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  String kategoriTerpilih = 'Playlist';

  final List<String> pilihanKategori = ['Playlist', 'Album', 'Lagu Disukai'];

  final aturanGridKoleksi = const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,
    mainAxisSpacing: 20,
    crossAxisSpacing: 16,
    childAspectRatio: 0.72,
  );

  String formatDurasiLagu(Duration durasi) {
    String menit = durasi.inMinutes.toString();
    String detik = (durasi.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  Future<void> muatUlangKoleksi() {
    return context.read<PlaylistProvider>().muatKoleksi();
  }

  void bukaDetailPlaylist(Playlist playlistDipilih) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPlaylistScreen(playlist: playlistDipilih),
      ),
    );
  }

  void tampilkanInfoSegeraHadir(String namaFitur) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$namaFitur segera hadir')));
  }

  Widget bangunIsiKoleksi(PlaylistProvider koleksi) {
    List<Playlist> daftarPlaylistSaya = koleksi.daftarPlaylistSaya;
    List<Album> daftarAlbumTersimpan = koleksi.daftarAlbumTersimpan;
    List<Lagu> daftarLaguDisukai = koleksi.daftarLaguDisukai;

    if (kategoriTerpilih == 'Playlist' && daftarPlaylistSaya.isNotEmpty) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
        itemCount: daftarPlaylistSaya.length,
        itemBuilder: (context, urutan) {
          Playlist playlistIni = daftarPlaylistSaya[urutan];
          return BarisPlaylistSaya(
            playlist: playlistIni,
            onDitekan: () => bukaDetailPlaylist(playlistIni),
          );
        },
      );
    }

    if (kategoriTerpilih == 'Album' && daftarAlbumTersimpan.isNotEmpty) {
      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: daftarAlbumTersimpan.length,
        gridDelegate: aturanGridKoleksi,
        itemBuilder: (context, urutan) {
          Album albumIni = daftarAlbumTersimpan[urutan];
          return KartuGridKoleksi(
            urlCover: albumIni.urlCover,
            judul: albumIni.judul,
            keterangan: '${albumIni.penyanyi} • ${albumIni.jumlahLagu} lagu',
            onDitekan: () =>
                tampilkanInfoSegeraHadir('Detail album ${albumIni.judul}'),
          );
        },
      );
    }

    if (kategoriTerpilih == 'Lagu Disukai' && daftarLaguDisukai.isNotEmpty) {
      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: daftarLaguDisukai.length,
        gridDelegate: aturanGridKoleksi,
        itemBuilder: (context, urutan) {
          Lagu laguIni = daftarLaguDisukai[urutan];
          return KartuGridKoleksi(
            urlCover: laguIni.urlCover,
            judul: laguIni.judul,
            keterangan:
                '${laguIni.penyanyi} • ${formatDurasiLagu(laguIni.durasi)}',
            onDitekan: () =>
                tampilkanInfoSegeraHadir('Memutar lagu ${laguIni.judul}'),
          );
        },
      );
    }

    bool isTabPlaylist = kategoriTerpilih == 'Playlist';
    bool isTabAlbum = kategoriTerpilih == 'Album';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        KoleksiMasihKosong(
          ikon: isTabPlaylist
              ? Icons.queue_music
              : isTabAlbum
              ? Icons.album_outlined
              : Icons.favorite_border,
          judul: isTabPlaylist
              ? 'Belum ada playlist'
              : isTabAlbum
              ? 'Belum ada album yang disimpan'
              : 'Belum ada lagu yang disukai',
          keterangan: isTabPlaylist
              ? 'Buat playlist pertamamu dan kumpulkan lagu favoritmu di sini'
              : isTabAlbum
              ? 'Simpan album yang kamu suka supaya gampang diputar lagi'
              : 'Tekan ikon hati pada lagu supaya tersimpan di sini',
          teksTombol: isTabPlaylist ? 'Buat Playlist' : 'Cari Lagu',
          onTombolDitekan: () => tampilkanInfoSegeraHadir(
            isTabPlaylist ? 'Fitur buat playlist' : 'Fitur cari lagu',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    PlaylistProvider koleksi = context.watch<PlaylistProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Koleksi Kamu',
          style: TextStyle(
            fontSize: 20,
            color: WarnaCapify.putih,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Buat playlist',
            icon: const Icon(Icons.add, color: WarnaCapify.krem, size: 28),
            onPressed: () => tampilkanInfoSegeraHadir('Fitur buat playlist'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Wrap(
                spacing: 10,
                children: pilihanKategori.map((namaKategori) {
                  bool isSedangDipilih = namaKategori == kategoriTerpilih;
                  return ChoiceChip(
                    label: Text(namaKategori),
                    selected: isSedangDipilih,
                    showCheckmark: false,
                    selectedColor: WarnaCapify.coklatTua,
                    backgroundColor: WarnaCapify.krem,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      color: isSedangDipilih
                          ? WarnaCapify.putih
                          : WarnaCapify.coklatGelap,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      setState(() => kategoriTerpilih = namaKategori);
                    },
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: koleksi.isMasihMuatPertamaKali
                  ? const Center(
                      child: CircularProgressIndicator(color: WarnaCapify.krem),
                    )
                  : RefreshIndicator(
                      color: WarnaCapify.coklatGelap,
                      backgroundColor: WarnaCapify.krem,
                      onRefresh: muatUlangKoleksi,
                      child: bangunIsiKoleksi(koleksi),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class KoleksiMasihKosong extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String keterangan;
  final String teksTombol;
  final VoidCallback onTombolDitekan;

  const KoleksiMasihKosong({
    super.key,
    required this.ikon,
    required this.judul,
    required this.keterangan,
    required this.teksTombol,
    required this.onTombolDitekan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: WarnaCapify.coklatTua.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(ikon, size: 48, color: WarnaCapify.krem),
          const SizedBox(height: 14),
          Text(
            judul,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: WarnaCapify.putih,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            keterangan,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WarnaCapify.krem,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WarnaCapify.krem,
              foregroundColor: WarnaCapify.coklatGelap,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: onTombolDitekan,
            child: Text(
              teksTombol,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class KartuGridKoleksi extends StatelessWidget {
  final String urlCover;
  final String judul;
  final String keterangan;
  final VoidCallback onDitekan;

  const KartuGridKoleksi({
    super.key,
    required this.urlCover,
    required this.judul,
    required this.keterangan,
    required this.onDitekan,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDitekan,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: CoverAlbum(urlCover: urlCover, lengkungSudut: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            judul,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WarnaCapify.putih,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            keterangan,
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
    );
  }
}

class BarisPlaylistSaya extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onDitekan;

  const BarisPlaylistSaya({
    super.key,
    required this.playlist,
    required this.onDitekan,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onDitekan,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: SizedBox(
        width: 56,
        height: 56,
        child: CoverAlbum(
          urlCover: playlist.urlCoverPlaylist,
          lengkungSudut: 8,
          isPakaiBayangan: false,
        ),
      ),
      title: Text(
        playlist.nama,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: WarnaCapify.putih,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        'Playlist • ${playlist.daftarLagu.length} lagu',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: WarnaCapify.krem,
          fontWeight: FontWeight.w300,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: WarnaCapify.krem,
      ),
    );
  }
}
