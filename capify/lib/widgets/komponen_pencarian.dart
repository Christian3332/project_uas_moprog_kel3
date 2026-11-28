import 'package:flutter/material.dart';

import '../models/album.dart';
import '../models/lagu.dart';
import '../utils/format_waktu.dart';
import '../utils/warna_capify.dart';
import 'cover_album.dart';

class BarisHasilLagu extends StatelessWidget {
  final Lagu lagu;
  final List<String> kataSorotanJudul;
  final List<String> kataSorotanPenyanyi;
  final VoidCallback onDipilih;
  final VoidCallback onLihatAlbum;
  final bool isLaguAktif;
  final bool isSedangDiputar;
  final bool isSedangMemuat;

  const BarisHasilLagu({
    super.key,
    required this.lagu,
    required this.kataSorotanJudul,
    required this.kataSorotanPenyanyi,
    required this.onDipilih,
    required this.onLihatAlbum,
    this.isLaguAktif = false,
    this.isSedangDiputar = false,
    this.isSedangMemuat = false,
  });

  Widget tandaDiCover() {
    Widget isiTanda;
    if (isSedangMemuat) {
      isiTanda = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: WarnaCapify.krem,
        ),
      );
    } else {
      isiTanda = Icon(
        isSedangDiputar ? Icons.graphic_eq_rounded : Icons.pause_rounded,
        color: WarnaCapify.krem,
        size: 28,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: WarnaCapify.coklatGelap.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: isiTanda,
    );
  }

  List<TextSpan> sorotiKataYangCocok(
    String teksAsli,
    List<String> kataDicari,
    TextStyle gayaBiasa,
    TextStyle gayaSorotan,
  ) {
    String teksHurufKecil = teksAsli.toLowerCase();

    bool panjangnyaBerubah = teksHurufKecil.length != teksAsli.length;
    if (teksAsli.isEmpty || kataDicari.isEmpty || panjangnyaBerubah) {
      return [TextSpan(text: teksAsli, style: gayaBiasa)];
    }

    List<bool> hurufDistabilo = List.filled(teksAsli.length, false);
    for (String kata in kataDicari) {
      int posisiKetemu = teksHurufKecil.indexOf(kata);
      while (posisiKetemu != -1) {
        for (int i = posisiKetemu; i < posisiKetemu + kata.length; i++) {
          hurufDistabilo[i] = true;
        }
        posisiKetemu = teksHurufKecil.indexOf(kata, posisiKetemu + kata.length);
      }
    }

    List<TextSpan> potonganTeks = [];
    int awalPotongan = 0;
    for (int i = 1; i <= teksAsli.length; i++) {
      bool sudahDiUjung = i == teksAsli.length;
      if (sudahDiUjung || hurufDistabilo[i] != hurufDistabilo[awalPotongan]) {
        potonganTeks.add(
          TextSpan(
            text: teksAsli.substring(awalPotongan, i),
            style: hurufDistabilo[awalPotongan] ? gayaSorotan : gayaBiasa,
          ),
        );
        awalPotongan = i;
      }
    }

    return potonganTeks;
  }

  @override
  Widget build(BuildContext context) {
    TextStyle gayaJudul = TextStyle(
      color: isLaguAktif ? WarnaCapify.krem : WarnaCapify.putih,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    const gayaPenyanyi = TextStyle(color: WarnaCapify.krem, fontSize: 13);
    Color warnaStabilo = WarnaCapify.krem.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isLaguAktif
            ? WarnaCapify.coklatTua
            : WarnaCapify.coklatTua.withValues(alpha: 0.45),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverAlbum(
                        urlCover: lagu.urlCover,
                        lengkungSudut: 10,
                        isPakaiBayangan: false,
                      ),
                      if (isLaguAktif) tandaDiCover(),
                    ],
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
                            kataSorotanJudul,
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
                                  kataSorotanPenyanyi,
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
                  FormatWaktu.durasiLagu(lagu.durasi),
                  style: TextStyle(
                    color: WarnaCapify.krem.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  onPressed: onLihatAlbum,
                  tooltip: 'Lihat album',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.album_outlined,
                    color: WarnaCapify.krem.withValues(alpha: 0.7),
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

class TampilanHasilKosong extends StatelessWidget {
  final String kataKunci;
  final String? saranEjaan;
  final bool isPakaiDataOffline;
  final ValueChanged<String> onPakaiKataLain;
  final VoidCallback onHapusPencarian;

  const TampilanHasilKosong({
    super.key,
    required this.kataKunci,
    required this.saranEjaan,
    required this.isPakaiDataOffline,
    required this.onPakaiKataLain,
    required this.onHapusPencarian,
  });

  static const List<String> daftarTips = [
    'Periksa lagi ejaannya, satu huruf saja bisa bikin beda',
    'Pakai kata yang lebih sedikit atau lebih umum',
    'Coba cari pakai nama penyanyinya',
  ];

  @override
  Widget build(BuildContext context) {
    String keterangan = isPakaiDataOffline
        ? 'Server belum bisa dihubungi, jadi pencarian ini cuma dari data offline yang isinya terbatas'
        : 'Belum ada lagu atau album yang cocok di katalog Capify';

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      children: [
        Icon(
          isPakaiDataOffline ? Icons.cloud_off_rounded : Icons.search_off,
          size: 56,
          color: WarnaCapify.krem,
        ),
        const SizedBox(height: 12),
        Text(
          'Tidak ada hasil untuk "$kataKunci"',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WarnaCapify.putih,
            fontSize: 16,
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
        if (saranEjaan != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Mungkin maksudmu',
            textAlign: TextAlign.center,
            style: TextStyle(color: WarnaCapify.krem, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Center(
            child: ActionChip(
              avatar: const Icon(
                Icons.auto_fix_high_rounded,
                size: 18,
                color: WarnaCapify.coklatGelap,
              ),
              label: Text(saranEjaan!),
              labelStyle: const TextStyle(
                color: WarnaCapify.coklatGelap,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: WarnaCapify.krem,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              onPressed: () => onPakaiKataLain(saranEjaan!),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WarnaCapify.coklatTua.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tips biar ketemu',
                style: TextStyle(
                  color: WarnaCapify.putih,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (String tips in daftarTips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: WarnaCapify.krem,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tips,
                          style: const TextStyle(
                            color: WarnaCapify.krem,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: onHapusPencarian,
            child: const Text(
              'Hapus pencarian',
              style: TextStyle(color: WarnaCapify.krem),
            ),
          ),
        ),
      ],
    );
  }
}

class JudulBagianHasil extends StatelessWidget {
  final String teks;

  const JudulBagianHasil({super.key, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 16,
          color: WarnaCapify.putih,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CatatanDataCadangan extends StatelessWidget {
  const CatatanDataCadangan({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WarnaCapify.coklatTua,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: WarnaCapify.krem),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Server belum bisa dihubungi, ini hasil dari data offline',
              style: TextStyle(color: WarnaCapify.krem, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class KartuAlbumHasil extends StatelessWidget {
  final Album album;
  final VoidCallback onDipilih;

  const KartuAlbumHasil({
    super.key,
    required this.album,
    required this.onDipilih,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: InkWell(
        onTap: onDipilih,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 124,
              height: 124,
              child: CoverAlbum(
                urlCover: album.urlCover,
                lengkungSudut: 12,
                isPakaiBayangan: false,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.judul,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WarnaCapify.putih,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${album.penyanyi} • ${album.jumlahLagu} lagu',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
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
