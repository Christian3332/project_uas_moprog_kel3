import 'package:flutter/material.dart';

import '../data/lagu_dummy.dart';
import '../models/lagu.dart';
import '../utils/warna_capify.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final kataKunciController = TextEditingController();

  List<Lagu> hasilPencarian = [];
  bool isSedangMencari = false;
  int urutanKetikan = 0;

  @override
  void dispose() {
    kataKunciController.dispose();
    super.dispose();
  }

  Future<void> cariLagu(String ketikanUser) async {
    String kataKunci = ketikanUser.trim().toLowerCase();
    urutanKetikan++;
    int ketikanIniKe = urutanKetikan;

    if (kataKunci.isEmpty) {
      setState(() {
        hasilPencarian = [];
        isSedangMencari = false;
      });
      return;
    }

    setState(() => isSedangMencari = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted || ketikanIniKe != urutanKetikan) return;

    List<Lagu> laguYangCocok = daftarLaguDummy.where((lagu) {
      bool judulCocok = lagu.judul.toLowerCase().contains(kataKunci);
      bool penyanyiCocok = lagu.penyanyi.toLowerCase().contains(kataKunci);
      return judulCocok || penyanyiCocok;
    }).toList();

    setState(() {
      hasilPencarian = laguYangCocok;
      isSedangMencari = false;
    });
  }

  void hapusKataKunci() {
    kataKunciController.clear();
    cariLagu('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Cari',
          style: TextStyle(
            fontSize: 22,
            color: WarnaCapify.putih,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                controller: kataKunciController,
                onChanged: cariLagu,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: WarnaCapify.coklatGelap),
                cursorColor: WarnaCapify.coklatGelap,
                decoration: InputDecoration(
                  hintText: 'Mau dengar apa hari ini?',
                  hintStyle: TextStyle(
                    color: WarnaCapify.coklatGelap.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: WarnaCapify.coklatGelap,
                  ),
                  suffixIcon: kataKunciController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: WarnaCapify.coklatGelap,
                          ),
                          onPressed: hapusKataKunci,
                        ),
                  filled: true,
                  fillColor: WarnaCapify.krem,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: tampilanIsiPencarian()),
          ],
        ),
      ),
    );
  }

  Widget tampilanIsiPencarian() {
    if (isSedangMencari) {
      return const Center(
        child: CircularProgressIndicator(color: WarnaCapify.krem),
      );
    }

    if (kataKunciController.text.trim().isEmpty) {
      return const PesanPencarianKosong(
        ikon: Icons.manage_search,
        pesan: 'Cari lagu atau penyanyi favoritmu',
      );
    }

    if (hasilPencarian.isEmpty) {
      return PesanPencarianKosong(
        ikon: Icons.music_off_outlined,
        pesan: 'Tidak ada hasil untuk "${kataKunciController.text.trim()}"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: hasilPencarian.length,
      itemBuilder: (context, index) {
        return BarisHasilLagu(lagu: hasilPencarian[index]);
      },
    );
  }
}

class BarisHasilLagu extends StatelessWidget {
  final Lagu lagu;

  const BarisHasilLagu({super.key, required this.lagu});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          lagu.urlCover,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 52,
            height: 52,
            color: WarnaCapify.coklatTua,
            child: const Icon(Icons.music_note, color: WarnaCapify.krem),
          ),
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
    );
  }
}

class PesanPencarianKosong extends StatelessWidget {
  final IconData ikon;
  final String pesan;

  const PesanPencarianKosong({
    super.key,
    required this.ikon,
    required this.pesan,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 56, color: WarnaCapify.krem),
            const SizedBox(height: 12),
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
      ),
    );
  }
}
