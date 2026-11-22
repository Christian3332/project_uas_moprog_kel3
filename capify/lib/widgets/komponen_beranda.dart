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
  final bool isSedangMencoba;
  final VoidCallback? onCobaLagi;
  final String? pesanKhusus;
  final IconData ikon;

  const SpandukDataCadangan({
    super.key,
    this.isSedangMencoba = false,
    this.onCobaLagi,
    this.pesanKhusus,
    this.ikon = Icons.cloud_off_rounded,
  });

  String teksSpanduk(bool isAdaTombolCobaLagi) {
    String? pesan = pesanKhusus;
    if (pesan != null && pesan.trim().isNotEmpty) return pesan;

    if (isAdaTombolCobaLagi) {
      return 'Server belum bisa dihubungi, Capy menampilkan lagu contoh dulu.';
    }
    return 'Server belum bisa dihubungi, Capy menampilkan lagu contoh dulu. '
        'Tarik ke bawah untuk coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    VoidCallback? aksiCobaLagi = onCobaLagi;
    bool isAdaTombolCobaLagi = aksiCobaLagi != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: EdgeInsets.fromLTRB(14, 6, isAdaTombolCobaLagi ? 6 : 14, 6),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: WarnaCapify.coklatTua,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WarnaCapify.krem.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 20, color: WarnaCapify.krem),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teksSpanduk(isAdaTombolCobaLagi),
              style: const TextStyle(
                color: WarnaCapify.krem,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          if (aksiCobaLagi != null) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 88,
              height: 40,
              child: isSedangMencoba
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: WarnaCapify.krem,
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: aksiCobaLagi,
                      child: const Text(
                        'Coba lagi',
                        style: TextStyle(
                          color: WarnaCapify.krem,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class KerangkaBerandaMemuat extends StatefulWidget {
  final bool isKoneksiLambat;

  const KerangkaBerandaMemuat({super.key, required this.isKoneksiLambat});

  @override
  State<KerangkaBerandaMemuat> createState() => _KerangkaBerandaMemuatState();
}

class _KerangkaBerandaMemuatState extends State<KerangkaBerandaMemuat>
    with SingleTickerProviderStateMixin {
  late final AnimationController pengaturKedipan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> tingkatTerang = Tween<double>(
    begin: 0.35,
    end: 0.8,
  ).animate(pengaturKedipan);

  @override
  void dispose() {
    pengaturKedipan.dispose();
    super.dispose();
  }

  Widget balokAbu({double? lebar, required double tinggi, double sudut = 8}) {
    return Container(
      width: lebar,
      height: tinggi,
      decoration: BoxDecoration(
        color: WarnaCapify.coklatTua,
        borderRadius: BorderRadius.circular(sudut),
      ),
    );
  }

  Widget kerangkaJudulBagian() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: balokAbu(lebar: 160, tinggi: 18),
    );
  }

  Widget kerangkaDeretanKartu() {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              balokAbu(lebar: 140, tinggi: 140, sudut: 12),
              const SizedBox(height: 10),
              balokAbu(lebar: 110, tinggi: 12),
              const SizedBox(height: 6),
              balokAbu(lebar: 70, tinggi: 10),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String teksStatus = widget.isKoneksiLambat
        ? 'Koneksi lagi lambat, Capy masih mencoba...'
        : 'Menyiapkan berandamu...';

    return Semantics(
      label: 'Beranda sedang dimuat',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: WarnaCapify.krem,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      teksStatus,
                      key: ValueKey(teksStatus),
                      style: const TextStyle(
                        color: WarnaCapify.krem,
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          FadeTransition(
            opacity: tingkatTerang,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: balokAbu(tinggi: 100, sudut: 16),
                ),
                const SizedBox(height: 28),
                kerangkaJudulBagian(),
                kerangkaDeretanKartu(),
                const SizedBox(height: 28),
                kerangkaJudulBagian(),
                kerangkaDeretanKartu(),
              ],
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
