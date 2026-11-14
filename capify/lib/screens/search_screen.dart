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
  final fokusKolomCari = FocusNode();

  List<Lagu> hasilPencarian = [];
  List<String> riwayatPencarian = [];
  bool isSedangMencari = false;
  int urutanKetikan = 0;

  final int batasRiwayat = 5;

  List<String> get saranPencarian {
    return daftarLaguDummy.map((lagu) => lagu.penyanyi).toSet().toList();
  }

  @override
  void dispose() {
    kataKunciController.dispose();
    fokusKolomCari.dispose();
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

  void simpanKeRiwayat(String kataKunci) {
    String kataBersih = kataKunci.trim();
    if (kataBersih.isEmpty) return;

    setState(() {
      riwayatPencarian.removeWhere(
        (kataLama) => kataLama.toLowerCase() == kataBersih.toLowerCase(),
      );
      riwayatPencarian.insert(0, kataBersih);
      if (riwayatPencarian.length > batasRiwayat) {
        riwayatPencarian = riwayatPencarian.sublist(0, batasRiwayat);
      }
    });
  }

  void pakaiKataKunci(String kataKunci) {
    kataKunciController.text = kataKunci;
    kataKunciController.selection = TextSelection.collapsed(
      offset: kataKunci.length,
    );
    fokusKolomCari.unfocus();
    simpanKeRiwayat(kataKunci);
    cariLagu(kataKunci);
  }

  void hapusKataKunci() {
    kataKunciController.clear();
    fokusKolomCari.requestFocus();
    cariLagu('');
  }

  void hapusSatuRiwayat(String kataKunci) {
    setState(() => riwayatPencarian.remove(kataKunci));
  }

  void hapusSemuaRiwayat() {
    setState(() => riwayatPencarian = []);
  }

  void pilihLaguDariHasil(Lagu lagu) {
    fokusKolomCari.unfocus();
    simpanKeRiwayat(kataKunciController.text);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Kamu memilih "${lagu.judul}"')),
      );
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
              child: kolomPencarian(),
            ),
            Expanded(child: tampilanIsiPencarian()),
          ],
        ),
      ),
    );
  }

  Widget kolomPencarian() {
    return TextField(
      controller: kataKunciController,
      focusNode: fokusKolomCari,
      onChanged: cariLagu,
      onSubmitted: simpanKeRiwayat,
      onTapOutside: (event) => fokusKolomCari.unfocus(),
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: WarnaCapify.coklatGelap),
      cursorColor: WarnaCapify.coklatGelap,
      decoration: InputDecoration(
        hintText: 'Mau dengar apa hari ini?',
        hintStyle: TextStyle(
          color: WarnaCapify.coklatGelap.withValues(alpha: 0.6),
        ),
        prefixIcon: const Icon(Icons.search, color: WarnaCapify.coklatGelap),
        suffixIcon: kataKunciController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, color: WarnaCapify.coklatGelap),
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
    );
  }

  Widget tampilanIsiPencarian() {
    String kataKunciSekarang = kataKunciController.text.trim();

    if (isSedangMencari) {
      return const Center(
        child: CircularProgressIndicator(color: WarnaCapify.krem),
      );
    }

    if (kataKunciSekarang.isEmpty) {
      return tampilanSebelumMencari();
    }

    if (hasilPencarian.isEmpty) {
      return PesanPencarianKosong(
        ikon: Icons.music_off_outlined,
        pesan: 'Tidak ada hasil untuk "$kataKunciSekarang"',
        keterangan: 'Coba periksa ejaannya atau pakai kata kunci lain',
        teksTombol: 'Hapus pencarian',
        onTombolDitekan: hapusKataKunci,
      );
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: hasilPencarian.length,
      itemBuilder: (context, index) {
        Lagu laguIni = hasilPencarian[index];
        return BarisHasilLagu(
          lagu: laguIni,
          onDipilih: () => pilihLaguDariHasil(laguIni),
        );
      },
    );
  }

  Widget tampilanSebelumMencari() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (riwayatPencarian.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: PesanPencarianKosong(
              ikon: Icons.manage_search,
              pesan: 'Cari lagu atau penyanyi favoritmu',
            ),
          )
        else ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pencarian terakhir',
                  style: TextStyle(
                    fontSize: 16,
                    color: WarnaCapify.putih,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: hapusSemuaRiwayat,
                child: const Text(
                  'Hapus semua',
                  style: TextStyle(color: WarnaCapify.krem),
                ),
              ),
            ],
          ),
          for (String kataLama in riwayatPencarian)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: WarnaCapify.krem),
              title: Text(
                kataLama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: WarnaCapify.putih),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: WarnaCapify.krem,
                ),
                onPressed: () => hapusSatuRiwayat(kataLama),
              ),
              onTap: () => pakaiKataKunci(kataLama),
            ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Coba cari',
          style: TextStyle(
            fontSize: 16,
            color: WarnaCapify.putih,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: saranPencarian.map((saran) {
            return ActionChip(
              label: Text(saran),
              labelStyle: const TextStyle(color: WarnaCapify.krem),
              backgroundColor: WarnaCapify.coklatTua,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              onPressed: () => pakaiKataKunci(saran),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class BarisHasilLagu extends StatelessWidget {
  final Lagu lagu;
  final VoidCallback onDipilih;

  const BarisHasilLagu({
    super.key,
    required this.lagu,
    required this.onDipilih,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: onDipilih,
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
  final String? keterangan;
  final String? teksTombol;
  final VoidCallback? onTombolDitekan;

  const PesanPencarianKosong({
    super.key,
    required this.ikon,
    required this.pesan,
    this.keterangan,
    this.teksTombol,
    this.onTombolDitekan,
  });

  @override
  Widget build(BuildContext context) {
    bool adaTombol = teksTombol != null && onTombolDitekan != null;

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
                color: WarnaCapify.putih,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (keterangan != null) ...[
              const SizedBox(height: 6),
              Text(
                keterangan!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: WarnaCapify.krem,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
            if (adaTombol) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onTombolDitekan,
                style: OutlinedButton.styleFrom(
                  foregroundColor: WarnaCapify.krem,
                  side: const BorderSide(color: WarnaCapify.krem),
                  shape: const StadiumBorder(),
                ),
                child: Text(teksTombol!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
