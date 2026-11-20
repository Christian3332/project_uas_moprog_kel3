import 'package:flutter/material.dart';

import '../models/lagu.dart';
import '../models/racikan_untukmu.dart';
import '../models/riwayat_putar.dart';
import '../utils/warna_capify.dart';
import 'cover_album.dart';

class JudulBagianBeranda extends StatelessWidget {
  final String judul;
  final String? keterangan;
  final Widget? tombolAksi;

  const JudulBagianBeranda({
    super.key,
    required this.judul,
    this.keterangan,
    this.tombolAksi,
  });

  @override
  Widget build(BuildContext context) {
    String? teksKeterangan = keterangan;
    Widget? aksi = tombolAksi;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 18,
                    color: WarnaCapify.putih,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (teksKeterangan != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    teksKeterangan,
                    style: TextStyle(
                      fontSize: 12,
                      color: WarnaCapify.krem.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?aksi,
        ],
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

class SpandukDataCadangan extends StatelessWidget {
  const SpandukDataCadangan({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: WarnaCapify.coklatTua,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WarnaCapify.krem.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 20, color: WarnaCapify.krem),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Server belum bisa dihubungi, Capy menampilkan lagu contoh dulu. '
              'Tarik ke bawah untuk coba lagi.',
              style: TextStyle(
                color: WarnaCapify.krem,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RakGeserHorizontal extends StatelessWidget {
  final double tinggiRak;
  final int jumlahItem;
  final Widget Function(BuildContext context, int index) pembuatItem;

  const RakGeserHorizontal({
    super.key,
    required this.tinggiRak,
    required this.jumlahItem,
    required this.pembuatItem,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: tinggiRak,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: jumlahItem,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: pembuatItem,
      ),
    );
  }
}

class KartuLanjutDengerin extends StatelessWidget {
  final RiwayatPutar riwayat;
  final bool isSedangDiputar;
  final bool isSedangDisiapkan;
  final VoidCallback onTekan;
  final VoidCallback onTekanTombolPutar;

  const KartuLanjutDengerin({
    super.key,
    required this.riwayat,
    required this.isSedangDiputar,
    required this.isSedangDisiapkan,
    required this.onTekan,
    required this.onTekanTombolPutar,
  });

  Widget isiTombolPutar() {
    if (isSedangDisiapkan) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: WarnaCapify.coklatGelap,
        ),
      );
    }

    return Icon(
      isSedangDiputar ? Icons.pause_rounded : Icons.play_arrow_rounded,
      size: 28,
      color: WarnaCapify.coklatGelap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: WarnaCapify.coklatTua,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTekan,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CoverAlbum(
                    urlCover: riwayat.lagu.urlCover,
                    lengkungSudut: 10,
                    isPakaiBayangan: false,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isSedangDiputar) ...[
                            const Icon(
                              Icons.graphic_eq_rounded,
                              size: 14,
                              color: WarnaCapify.krem,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isSedangDiputar
                                ? 'Sedang diputar'
                                : 'Lanjut dengerin',
                            style: const TextStyle(
                              color: WarnaCapify.krem,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        riwayat.lagu.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WarnaCapify.putih,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${riwayat.lagu.penyanyi} • ${riwayat.teksWaktuDiputar}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: WarnaCapify.krem,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: isSedangDisiapkan ? null : onTekanTombolPutar,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: isiTombolPutar()),
                    ),
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

class KartuLaguKecil extends StatelessWidget {
  final Lagu lagu;
  final String keterangan;
  final VoidCallback onTekan;

  const KartuLaguKecil({
    super.key,
    required this.lagu,
    required this.keterangan,
    required this.onTekan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CoverAlbum(
                urlCover: lagu.urlCover,
                lengkungSudut: 12,
                isPakaiBayangan: false,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lagu.judul,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WarnaCapify.putih,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              lagu.penyanyi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              keterangan,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KartuRacikanUntukmu extends StatelessWidget {
  final RacikanUntukmu racikan;
  final VoidCallback onTekan;

  const KartuRacikanUntukmu({
    super.key,
    required this.racikan,
    required this.onTekan,
  });

  String? get teksLencana {
    if (racikan.isGenreFavorit) return 'Favorit';
    if (racikan.jumlahLaguFamiliar > 0) return 'Cocok';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String? lencana = teksLencana;

    return SizedBox(
      width: 150,
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CoverAlbum(
                      urlCover: racikan.playlist.urlCoverPlaylist,
                      lengkungSudut: 12,
                      isPakaiBayangan: false,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                      decoration: BoxDecoration(
                        color: racikan.warnaAksen.withValues(alpha: 0.92),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        racikan.playlist.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WarnaCapify.putih,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (lencana != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: WarnaCapify.krem,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          lencana,
                          style: const TextStyle(
                            color: WarnaCapify.coklatGelap,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              racikan.playlist.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
