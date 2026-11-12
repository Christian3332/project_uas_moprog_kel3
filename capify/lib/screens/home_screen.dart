import 'package:flutter/material.dart';

import '../utils/warna_capify.dart';

class HomeScreen extends StatefulWidget {
  final String namaPengguna;

  const HomeScreen({super.key, this.namaPengguna = 'Capy Lovers'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isHalamanSedangDimuat = true;

  @override
  void initState() {
    super.initState();
    muatIsiBeranda();
  }

  Future<void> muatIsiBeranda() async {
    setState(() => isHalamanSedangDimuat = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => isHalamanSedangDimuat = false);
  }

  String sapaanSesuaiJam() {
    int jamSekarang = DateTime.now().hour;
    if (jamSekarang >= 4 && jamSekarang < 11) return 'Selamat pagi';
    if (jamSekarang >= 11 && jamSekarang < 15) return 'Selamat siang';
    if (jamSekarang >= 15 && jamSekarang < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sapaanSesuaiJam(),
              style: const TextStyle(
                fontSize: 13,
                color: WarnaCapify.krem,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              widget.namaPengguna,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                color: WarnaCapify.putih,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: WarnaCapify.krem),
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Fitur notifikasi segera hadir')),
                );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isHalamanSedangDimuat
            ? const Center(
                child: CircularProgressIndicator(color: WarnaCapify.krem),
              )
            : RefreshIndicator(
                color: WarnaCapify.coklatGelap,
                backgroundColor: WarnaCapify.krem,
                onRefresh: muatIsiBeranda,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: const [
                    JudulBagianBeranda(judul: 'Terakhir diputar'),
                    KotakBelumAdaIsi(
                      ikon: Icons.history,
                      pesan: 'Belum ada lagu yang kamu putar',
                    ),
                    SizedBox(height: 28),
                    JudulBagianBeranda(judul: 'Rekomendasi untukmu'),
                    KotakBelumAdaIsi(
                      ikon: Icons.library_music_outlined,
                      pesan: 'Rekomendasi lagu akan muncul di sini',
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class JudulBagianBeranda extends StatelessWidget {
  final String judul;

  const JudulBagianBeranda({super.key, required this.judul});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        judul,
        style: const TextStyle(
          fontSize: 18,
          color: WarnaCapify.putih,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class KotakBelumAdaIsi extends StatelessWidget {
  final IconData ikon;
  final String pesan;

  const KotakBelumAdaIsi({super.key, required this.ikon, required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: WarnaCapify.coklatTua.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ikon, size: 36, color: WarnaCapify.krem),
          const SizedBox(height: 10),
          Text(
            pesan,
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
}
