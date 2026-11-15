import 'package:flutter/material.dart';

import '../data/album_dummy.dart';
import '../models/album.dart';
import '../models/lagu.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';

class DetailAlbumScreen extends StatefulWidget {
  final Lagu laguDipilih;

  const DetailAlbumScreen({super.key, required this.laguDipilih});

  @override
  State<DetailAlbumScreen> createState() => _DetailAlbumScreenState();
}

class _DetailAlbumScreenState extends State<DetailAlbumScreen> {
  bool isAlbumSedangDicari = true;
  bool isAlbumDisukai = false;
  Album? albumDitemukan;

  @override
  void initState() {
    super.initState();
    muatAlbumDariLagu();
  }

  Future<void> muatAlbumDariLagu() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      albumDitemukan = cariAlbumYangCocok(widget.laguDipilih);
      isAlbumSedangDicari = false;
    });
  }

  Album? cariAlbumYangCocok(Lagu lagu) {
    String penyanyiLagu = lagu.penyanyi.toLowerCase();
    String judulLagu = lagu.judul.toLowerCase();
    Album? albumPenyanyiSama;

    for (Album album in daftarAlbumTersimpanDummy) {
      if (album.penyanyi.toLowerCase() != penyanyiLagu) continue;
      if (album.judul.toLowerCase() == judulLagu) return album;
      albumPenyanyiSama ??= album;
    }

    return albumPenyanyiSama;
  }

  String formatDurasiLagu(Duration durasi) {
    String menit = durasi.inMinutes.toString();
    String detik = (durasi.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
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

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(child: bangunIsiHalaman()),
    );
  }

  Widget bangunIsiHalaman() {
    if (isAlbumSedangDicari) {
      return const Center(
        child: CircularProgressIndicator(color: WarnaCapify.krem),
      );
    }

    Album? album = albumDitemukan;
    if (album == null) {
      return pesanAlbumTidakAda();
    }

    return ListView(
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
                color: isAlbumDisukai ? WarnaCapify.krem : WarnaCapify.putih,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () =>
                  tampilkanPesanSingkat('Pemutaran album segera hadir'),
              style: FilledButton.styleFrom(
                backgroundColor: WarnaCapify.krem,
                foregroundColor: WarnaCapify.coklatGelap,
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
        const Text(
          'Lagu yang kamu cari',
          style: TextStyle(
            fontSize: 16,
            color: WarnaCapify.putih,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        barisLaguDipilih(),
        const SizedBox(height: 20),
        kotakDaftarLaguSegeraHadir(album.jumlahLagu),
      ],
    );
  }

  Widget barisLaguDipilih() {
    Lagu lagu = widget.laguDipilih;

    return Container(
      decoration: BoxDecoration(
        color: WarnaCapify.coklatTua.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
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

  Widget kotakDaftarLaguSegeraHadir(int jumlahLagu) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: WarnaCapify.coklatTua),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.queue_music_rounded,
            size: 36,
            color: WarnaCapify.krem,
          ),
          const SizedBox(height: 8),
          Text(
            'Daftar lengkap $jumlahLagu lagu di album ini segera hadir',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WarnaCapify.krem,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget pesanAlbumTidakAda() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.album_outlined, size: 56, color: WarnaCapify.krem),
            const SizedBox(height: 12),
            const Text(
              'Album belum tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: WarnaCapify.putih,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lagu "${widget.laguDipilih.judul}" belum masuk ke album mana pun',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WarnaCapify.krem,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: WarnaCapify.krem,
                side: const BorderSide(color: WarnaCapify.krem),
                shape: const StadiumBorder(),
              ),
              child: const Text('Kembali ke pencarian'),
            ),
          ],
        ),
      ),
    );
  }
}
