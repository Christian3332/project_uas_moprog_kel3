import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/lagu_per_kategori_dummy.dart';
import '../models/kategori_musik.dart';
import '../models/lagu.dart';
import '../providers/audio_provider.dart';
import '../utils/format_waktu.dart';
import '../utils/kunci_lagu.dart';
import '../utils/warna_capify.dart';

class DetailKategoriScreen extends StatefulWidget {
  final KategoriMusik kategori;

  const DetailKategoriScreen({super.key, required this.kategori});

  @override
  State<DetailKategoriScreen> createState() => _DetailKategoriScreenState();
}

class _DetailKategoriScreenState extends State<DetailKategoriScreen> {
  bool isLaguSedangDimuat = true;
  List<Lagu> laguDiKategori = [];

  @override
  void initState() {
    super.initState();
    muatLaguKategori();
  }

  Future<void> muatLaguKategori() async {
    setState(() => isLaguSedangDimuat = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    List<Lagu>? laguDariData = laguPerKategoriDummy[widget.kategori.nama];

    setState(() {
      laguDiKategori = laguDariData == null ? [] : List.of(laguDariData);
      isLaguSedangDimuat = false;
    });
  }

  String ringkasanIsiKategori() {
    if (laguDiKategori.isEmpty) return 'Belum ada lagu';

    Duration totalDurasi = laguDiKategori.fold(
      Duration.zero,
      (jumlahSementara, lagu) => jumlahSementara + lagu.durasi,
    );

    int jam = totalDurasi.inHours;
    int menit = totalDurasi.inMinutes % 60;
    String teksDurasi = jam > 0 ? '$jam jam $menit menit' : '$menit menit';

    return '${laguDiKategori.length} lagu • $teksDurasi';
  }

  void putarLagu(int urutan) {
    AudioProvider audio = context.read<AudioProvider>();
    if (!audio.mintaIzinPemutaran()) return;

    audio.mulaiAntrian(
      laguDiKategori,
      indexMulai: urutan,
      namaAntrian: 'Kategori ${widget.kategori.nama}',
    );
  }

  @override
  Widget build(BuildContext context) {
    String? kunciLaguAktif = context.select<AudioProvider, String?>((audio) {
      Lagu? laguDiPemutar = audio.laguSekarang;
      return laguDiPemutar == null ? null : kunciUnikLagu(laguDiPemutar);
    });
    bool isAudioSedangDiputar = context.select<AudioProvider, bool>(
      (audio) => audio.isLaguSedangDiputar,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.kategori.warnaKartu,
        foregroundColor: WarnaCapify.putih,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.kategori.nama,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLaguSedangDimuat
          ? const Center(
              child: CircularProgressIndicator(color: WarnaCapify.krem),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                headerKategori(),
                if (laguDiKategori.isEmpty)
                  pesanKategoriKosong()
                else
                  for (int urutan = 0; urutan < laguDiKategori.length; urutan++)
                    BarisLaguKategori(
                      nomorUrut: urutan + 1,
                      lagu: laguDiKategori[urutan],
                      teksDurasi: FormatWaktu.durasiLagu(
                        laguDiKategori[urutan].durasi,
                      ),
                      isSedangDiputar:
                          isAudioSedangDiputar &&
                          kunciLaguAktif ==
                              kunciUnikLagu(laguDiKategori[urutan]),
                      onDitekan: () => putarLagu(urutan),
                    ),
              ],
            ),
    );
  }

  Widget headerKategori() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [widget.kategori.warnaKartu, WarnaCapify.coklatGelap],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: WarnaCapify.coklatGelap.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              widget.kategori.ikon,
              size: 44,
              color: WarnaCapify.krem,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kategori.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    color: WarnaCapify.putih,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ringkasanIsiKategori(),
                  style: const TextStyle(
                    color: WarnaCapify.krem,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pesanKategoriKosong() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
      child: Column(
        children: [
          const Icon(
            Icons.music_off_outlined,
            size: 48,
            color: WarnaCapify.krem,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada lagu di kategori ini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: WarnaCapify.putih,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lagu ${widget.kategori.nama} akan muncul di sini nanti',
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

class BarisLaguKategori extends StatelessWidget {
  final int nomorUrut;
  final Lagu lagu;
  final String teksDurasi;
  final bool isSedangDiputar;
  final VoidCallback onDitekan;

  const BarisLaguKategori({
    super.key,
    required this.nomorUrut,
    required this.lagu,
    required this.teksDurasi,
    required this.isSedangDiputar,
    required this.onDitekan,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onDitekan,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: isSedangDiputar
                ? const Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: WarnaCapify.krem,
                  )
                : Text(
                    '$nomorUrut',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: WarnaCapify.krem),
                  ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              lagu.urlCover,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: WarnaCapify.coklatTua,
                child: const Icon(Icons.music_note, color: WarnaCapify.krem),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        lagu.judul,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isSedangDiputar ? WarnaCapify.krem : WarnaCapify.putih,
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
        teksDurasi,
        style: const TextStyle(color: WarnaCapify.krem),
      ),
    );
  }
}
