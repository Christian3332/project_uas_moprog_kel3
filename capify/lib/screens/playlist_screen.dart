import 'package:flutter/material.dart';

import '../utils/warna_capify.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool isKoleksiSedangDimuat = true;
  String kategoriTerpilih = 'Playlist';

  final List<String> pilihanKategori = ['Playlist', 'Lagu Disukai'];

  @override
  void initState() {
    super.initState();
    muatKoleksiPengguna();
  }

  Future<void> muatKoleksiPengguna() async {
    setState(() => isKoleksiSedangDimuat = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => isKoleksiSedangDimuat = false);
  }

  void tampilkanInfoSegeraHadir(String namaFitur) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$namaFitur segera hadir')),
      );
  }

  @override
  Widget build(BuildContext context) {
    bool isTabPlaylist = kategoriTerpilih == 'Playlist';

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
              child: isKoleksiSedangDimuat
                  ? const Center(
                      child: CircularProgressIndicator(color: WarnaCapify.krem),
                    )
                  : RefreshIndicator(
                      color: WarnaCapify.coklatGelap,
                      backgroundColor: WarnaCapify.krem,
                      onRefresh: muatKoleksiPengguna,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          KoleksiMasihKosong(
                            ikon: isTabPlaylist
                                ? Icons.queue_music
                                : Icons.favorite_border,
                            judul: isTabPlaylist
                                ? 'Belum ada playlist'
                                : 'Belum ada lagu yang disukai',
                            keterangan: isTabPlaylist
                                ? 'Buat playlist pertamamu dan kumpulkan lagu favoritmu di sini'
                                : 'Tekan ikon hati pada lagu supaya tersimpan di sini',
                            teksTombol:
                                isTabPlaylist ? 'Buat Playlist' : 'Cari Lagu',
                            onTombolDitekan: () => tampilkanInfoSegeraHadir(
                              isTabPlaylist
                                  ? 'Fitur buat playlist'
                                  : 'Fitur cari lagu',
                            ),
                          ),
                        ],
                      ),
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
