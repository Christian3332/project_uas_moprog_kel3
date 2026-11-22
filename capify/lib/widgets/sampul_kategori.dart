import 'package:flutter/material.dart';

import '../data/lagu_per_kategori_dummy.dart';
import '../models/lagu.dart';
import '../utils/warna_capify.dart';

const double ukuranSampulKategori = 68;

String? ambilUrlSampulKategori(String namaKategori) {
  List<Lagu> laguDiKategori = laguPerKategoriDummy[namaKategori] ?? [];
  for (Lagu lagu in laguDiKategori) {
    String urlBersih = lagu.urlCover.trim();
    if (urlBersih.isNotEmpty) return urlBersih;
  }
  return null;
}

int hitungLebarDecode(double rasioPikselLayar) {
  double rasioAman = rasioPikselLayar <= 0 ? 1 : rasioPikselLayar;
  return (ukuranSampulKategori * rasioAman).ceil();
}

ImageProvider buatPenyediaSampul(String urlSampul, double rasioPikselLayar) {
  return ResizeImage(
    NetworkImage(urlSampul),
    width: hitungLebarDecode(rasioPikselLayar),
  );
}

class SampulKategori extends StatelessWidget {
  final String? urlSampul;
  final IconData ikonCadangan;

  const SampulKategori({
    super.key,
    required this.urlSampul,
    required this.ikonCadangan,
  });

  @override
  Widget build(BuildContext context) {
    Widget ikonKategori = Center(
      child: Icon(
        ikonCadangan,
        size: ukuranSampulKategori * 0.9,
        color: WarnaCapify.krem.withValues(alpha: 0.35),
      ),
    );

    String? url = urlSampul;
    if (url == null) return ikonKategori;

    return Stack(
      fit: StackFit.expand,
      children: [
        ikonKategori,
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image(
            image: buatPenyediaSampul(
              url,
              MediaQuery.devicePixelRatioOf(context),
            ),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            frameBuilder: (context, gambar, nomorFrame, isLangsungAdaDiCache) {
              if (isLangsungAdaDiCache) return gambar;
              return AnimatedOpacity(
                opacity: nomorFrame == null ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: gambar,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
