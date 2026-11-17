import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lagu.dart';
import '../providers/search_provider.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';
import 'detail_album_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController kataKunciController;
  final fokusKolomCari = FocusNode();

  @override
  void initState() {
    super.initState();
    String kataKunciTersimpan = context.read<SearchProvider>().kataKunci;
    kataKunciController = TextEditingController(text: kataKunciTersimpan);
  }

  @override
  void dispose() {
    kataKunciController.dispose();
    fokusKolomCari.dispose();
    super.dispose();
  }

  void pakaiKataKunci(String kataKunci) {
    SearchProvider pencarian = context.read<SearchProvider>();
    kataKunciController.text = kataKunci;
    kataKunciController.selection = TextSelection.collapsed(
      offset: kataKunci.length,
    );
    fokusKolomCari.unfocus();
    pencarian.simpanKeRiwayat(kataKunci);
    pencarian.cariLagu(kataKunci);
  }

  void hapusKataKunci() {
    kataKunciController.clear();
    fokusKolomCari.requestFocus();
    context.read<SearchProvider>().kosongkanPencarian();
  }

  void pilihLaguDariHasil(Lagu lagu) {
    fokusKolomCari.unfocus();
    context.read<SearchProvider>().simpanKeRiwayat(kataKunciController.text);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailAlbumScreen(laguDipilih: lagu),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SearchProvider pencarian = context.watch<SearchProvider>();

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
              child: kolomPencarian(pencarian),
            ),
            Expanded(child: tampilanIsiPencarian(pencarian)),
          ],
        ),
      ),
    );
  }

  Widget kolomPencarian(SearchProvider pencarian) {
    return TextField(
      controller: kataKunciController,
      focusNode: fokusKolomCari,
      onChanged: pencarian.cariLagu,
      onSubmitted: pencarian.simpanKeRiwayat,
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
        suffixIcon: pencarian.kataKunci.isEmpty
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

  Widget tampilanIsiPencarian(SearchProvider pencarian) {
    String kataKunciSekarang = pencarian.kataKunciBersih;
    List<Lagu> hasilPencarian = pencarian.hasilPencarian;

    if (pencarian.isSedangMencari) {
      return const Center(
        child: CircularProgressIndicator(color: WarnaCapify.krem),
      );
    }

    if (pencarian.isKolomCariKosong) {
      return tampilanSebelumMencari(pencarian);
    }

    if (pencarian.isHasilKosong) {
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
      itemCount: hasilPencarian.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${hasilPencarian.length} lagu ditemukan',
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          );
        }

        Lagu laguIni = hasilPencarian[index - 1];
        return BarisHasilLagu(
          lagu: laguIni,
          kataKunci: kataKunciSekarang,
          onDipilih: () => pilihLaguDariHasil(laguIni),
        );
      },
    );
  }

  Widget tampilanSebelumMencari(SearchProvider pencarian) {
    List<String> riwayatPencarian = pencarian.riwayatPencarian;

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
                onPressed: pencarian.hapusSemuaRiwayat,
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
                onPressed: () => pencarian.hapusSatuRiwayat(kataLama),
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
          children: pencarian.saranPencarian.map((saran) {
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
  final String kataKunci;
  final VoidCallback onDipilih;

  const BarisHasilLagu({
    super.key,
    required this.lagu,
    required this.kataKunci,
    required this.onDipilih,
  });

  String formatDurasi(Duration durasi) {
    String menit = durasi.inMinutes.toString();
    String detik = (durasi.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  List<TextSpan> sorotiKataYangCocok(
    String teksAsli,
    TextStyle gayaBiasa,
    TextStyle gayaSorotan,
  ) {
    String kataDicari = kataKunci.trim().toLowerCase();
    String teksHurufKecil = teksAsli.toLowerCase();

    bool panjangnyaBerubah = teksHurufKecil.length != teksAsli.length;
    if (kataDicari.isEmpty || panjangnyaBerubah) {
      return [TextSpan(text: teksAsli, style: gayaBiasa)];
    }

    List<TextSpan> potonganTeks = [];
    int posisiTerakhir = 0;
    int posisiKetemu = teksHurufKecil.indexOf(kataDicari);

    while (posisiKetemu != -1) {
      if (posisiKetemu > posisiTerakhir) {
        potonganTeks.add(
          TextSpan(
            text: teksAsli.substring(posisiTerakhir, posisiKetemu),
            style: gayaBiasa,
          ),
        );
      }

      int ujungKataCocok = posisiKetemu + kataDicari.length;
      potonganTeks.add(
        TextSpan(
          text: teksAsli.substring(posisiKetemu, ujungKataCocok),
          style: gayaSorotan,
        ),
      );

      posisiTerakhir = ujungKataCocok;
      posisiKetemu = teksHurufKecil.indexOf(kataDicari, posisiTerakhir);
    }

    if (posisiTerakhir < teksAsli.length) {
      potonganTeks.add(
        TextSpan(text: teksAsli.substring(posisiTerakhir), style: gayaBiasa),
      );
    }

    return potonganTeks;
  }

  @override
  Widget build(BuildContext context) {
    const gayaJudul = TextStyle(
      color: WarnaCapify.putih,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    const gayaPenyanyi = TextStyle(color: WarnaCapify.krem, fontSize: 13);
    Color warnaStabilo = WarnaCapify.krem.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: WarnaCapify.coklatTua.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onDipilih,
          splashColor: WarnaCapify.krem.withValues(alpha: 0.12),
          highlightColor: WarnaCapify.krem.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CoverAlbum(
                    urlCover: lagu.urlCover,
                    lengkungSudut: 10,
                    isPakaiBayangan: false,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: sorotiKataYangCocok(
                            lagu.judul,
                            gayaJudul,
                            gayaJudul.copyWith(
                              fontWeight: FontWeight.w800,
                              backgroundColor: warnaStabilo,
                            ),
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: WarnaCapify.krem,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Lagu',
                              style: TextStyle(
                                color: WarnaCapify.coklatGelap,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: sorotiKataYangCocok(
                                  lagu.penyanyi,
                                  gayaPenyanyi,
                                  gayaPenyanyi.copyWith(
                                    color: WarnaCapify.putih,
                                    fontWeight: FontWeight.w700,
                                    backgroundColor: warnaStabilo,
                                  ),
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formatDurasi(lagu.durasi),
                  style: TextStyle(
                    color: WarnaCapify.krem.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  color: WarnaCapify.krem.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
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
