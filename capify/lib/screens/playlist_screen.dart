import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/album.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';
import '../providers/audio_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/koleksi_service.dart';
import '../utils/format_waktu.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';
import '../widgets/form_buat_playlist.dart';
import '../widgets/komponen_beranda.dart';
import 'detail_playlist_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  String kategoriTerpilih = 'Playlist';
  String? idPlaylistBaruDisorot;

  final pengendaliGulirPlaylist = ScrollController();
  final Duration lamaSorotanPlaylistBaru = const Duration(seconds: 2);

  final List<String> pilihanKategori = ['Playlist', 'Album', 'Lagu Disukai'];

  final aturanGridKoleksi = const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,
    mainAxisSpacing: 20,
    crossAxisSpacing: 16,
    childAspectRatio: 0.72,
  );

  @override
  void dispose() {
    pengendaliGulirPlaylist.dispose();
    super.dispose();
  }

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  void tampilkanInfoSegeraHadir(String namaFitur) {
    tampilkanPesan('$namaFitur segera hadir');
  }

  Future<void> muatUlangKoleksi() async {
    PlaylistProvider koleksi = context.read<PlaylistProvider>();
    await koleksi.muatKoleksi();
    if (!mounted) return;

    String? pesanGagal = koleksi.pesanGagal;
    if (pesanGagal != null) tampilkanPesan(pesanGagal);
  }

  Widget bangunAreaKoleksi(PlaylistProvider koleksi) {
    String? pesanGagal = koleksi.pesanGagal;

    if (!koleksi.isKoleksiSudahPernahDimuat && pesanGagal != null) {
      return Center(
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
                onPressed: koleksi.muatKoleksi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarnaCapify.krem,
                  foregroundColor: WarnaCapify.coklatGelap,
                ),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (!koleksi.isKoleksiSudahPernahDimuat) {
      return const Center(
        child: CircularProgressIndicator(color: WarnaCapify.krem),
      );
    }

    return RefreshIndicator(
      color: WarnaCapify.coklatGelap,
      backgroundColor: WarnaCapify.krem,
      onRefresh: muatUlangKoleksi,
      child: bangunIsiKoleksi(koleksi),
    );
  }

  void bukaDetailPlaylist(Playlist playlistDipilih) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPlaylistScreen(playlist: playlistDipilih),
      ),
    );
  }

  Future<void> bukaFormBuatPlaylist() async {
    String? namaPlaylistBaru = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WarnaCapify.coklatGelap,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (konteksSheet) => const FormBuatPlaylist(),
    );

    if (!mounted || namaPlaylistBaru == null) return;

    String? idPlaylistBaru = cariIdPlaylistDariNama(namaPlaylistBaru);
    setState(() {
      kategoriTerpilih = 'Playlist';
      idPlaylistBaruDisorot = idPlaylistBaru;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => gulirKePalingAtas());
    hapusSorotanSetelahJeda(idPlaylistBaru);

    tampilkanPesan('Playlist "$namaPlaylistBaru" berhasil dibuat');
  }

  String? cariIdPlaylistDariNama(String namaPlaylist) {
    String namaDicari = namaPlaylist.trim().toLowerCase();
    for (Playlist playlist
        in context.read<PlaylistProvider>().daftarPlaylistSaya) {
      if (playlist.nama.toLowerCase() == namaDicari) return playlist.id;
    }
    return null;
  }

  void gulirKePalingAtas() {
    if (!mounted || !pengendaliGulirPlaylist.hasClients) return;
    pengendaliGulirPlaylist.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Future<void> hapusSorotanSetelahJeda(String? idYangDisorot) async {
    if (idYangDisorot == null) return;

    await Future.delayed(lamaSorotanPlaylistBaru);
    if (!mounted || idPlaylistBaruDisorot != idYangDisorot) return;

    setState(() => idPlaylistBaruDisorot = null);
  }

  bool isPlaylistSedangAktif(
    Playlist playlist,
    String namaAntrianAktif,
    String? kunciLaguAktif,
  ) {
    if (kunciLaguAktif == null) return false;
    if (namaAntrianAktif != playlist.nama) return false;

    return playlist.daftarLagu.any(
      (lagu) => KoleksiService.buatKunciLagu(lagu) == kunciLaguAktif,
    );
  }

  void putarPlaylist(Playlist playlist) {
    if (playlist.daftarLagu.isEmpty) {
      tampilkanPesan('Playlist ini belum punya lagu');
      return;
    }

    AudioProvider audio = context.read<AudioProvider>();
    if (!audio.mintaIzinPemutaran()) return;

    Lagu? laguDiPemutar = audio.laguSekarang;
    String? kunciLaguAktif = laguDiPemutar == null
        ? null
        : KoleksiService.buatKunciLagu(laguDiPemutar);

    if (isPlaylistSedangAktif(playlist, audio.namaAntrian, kunciLaguAktif)) {
      audio.togglePutarJeda();
      return;
    }

    audio.mulaiAntrian(playlist.daftarLagu, namaAntrian: playlist.nama);
  }

  Widget bangunIsiKoleksi(PlaylistProvider koleksi) {
    List<Playlist> daftarPlaylistSaya = koleksi.daftarPlaylistSaya;
    List<Album> daftarAlbumTersimpan = koleksi.daftarAlbumTersimpan;
    List<Lagu> daftarLaguDisukai = koleksi.daftarLaguDisukai;

    if (kategoriTerpilih == 'Playlist' && daftarPlaylistSaya.isNotEmpty) {
      String namaAntrianAktif = context.select<AudioProvider, String>(
        (audio) => audio.namaAntrian,
      );
      bool isAudioSedangDiputar = context.select<AudioProvider, bool>(
        (audio) => audio.isLaguSedangDiputar,
      );
      String? kunciLaguAktif = context.select<AudioProvider, String?>((audio) {
        Lagu? laguDiPemutar = audio.laguSekarang;
        return laguDiPemutar == null
            ? null
            : KoleksiService.buatKunciLagu(laguDiPemutar);
      });

      return ListView.builder(
        controller: pengendaliGulirPlaylist,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
        itemCount: daftarPlaylistSaya.length,
        itemBuilder: (context, urutan) {
          Playlist playlistIni = daftarPlaylistSaya[urutan];
          bool isPlaylistIniDiputar =
              isAudioSedangDiputar &&
              isPlaylistSedangAktif(
                playlistIni,
                namaAntrianAktif,
                kunciLaguAktif,
              );

          return BarisPlaylistSaya(
            playlist: playlistIni,
            isSedangDiputar: isPlaylistIniDiputar,
            isBaruDibuat: playlistIni.id == idPlaylistBaruDisorot,
            onDitekan: () => bukaDetailPlaylist(playlistIni),
            onTekanPutar: () => putarPlaylist(playlistIni),
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
                '${laguIni.penyanyi} • ${FormatWaktu.durasiLagu(laguIni.durasi)}',
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
          onTombolDitekan: isTabPlaylist
              ? bukaFormBuatPlaylist
              : () => tampilkanInfoSegeraHadir('Fitur cari lagu'),
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
            onPressed: bukaFormBuatPlaylist,
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
            if (koleksi.isMemakaiDataCadangan) const SpandukDataCadangan(),
            Expanded(child: bangunAreaKoleksi(koleksi)),
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
  final bool isSedangDiputar;
  final bool isBaruDibuat;
  final VoidCallback onDitekan;
  final VoidCallback onTekanPutar;

  const BarisPlaylistSaya({
    super.key,
    required this.playlist,
    required this.isSedangDiputar,
    this.isBaruDibuat = false,
    required this.onDitekan,
    required this.onTekanPutar,
  });

  @override
  Widget build(BuildContext context) {
    bool isPlaylistKosong = playlist.daftarLagu.isEmpty;
    String keteranganPlaylist = isSedangDiputar
        ? 'Sedang diputar • ${playlist.daftarLagu.length} lagu'
        : 'Playlist • ${playlist.daftarLagu.length} lagu';

    return ListTile(
      onTap: onDitekan,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isBaruDibuat
          ? WarnaCapify.coklatTua.withValues(alpha: 0.8)
          : null,
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
        keteranganPlaylist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: WarnaCapify.krem,
          fontWeight: isSedangDiputar ? FontWeight.w600 : FontWeight.w300,
        ),
      ),
      trailing: IconButton(
        tooltip: isSedangDiputar
            ? 'Jeda ${playlist.nama}'
            : 'Putar ${playlist.nama}',
        onPressed: onTekanPutar,
        iconSize: 36,
        icon: Icon(
          isSedangDiputar
              ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_fill_rounded,
          color: isPlaylistKosong
              ? WarnaCapify.krem.withValues(alpha: 0.35)
              : WarnaCapify.krem,
        ),
      ),
    );
  }
}
