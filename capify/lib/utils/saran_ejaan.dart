import 'dart:math';

int hitungJarakKetik(String kataA, String kataB) {
  if (kataA == kataB) return 0;
  if (kataA.isEmpty) return kataB.length;
  if (kataB.isEmpty) return kataA.length;

  List<int> barisSebelumnya = List.generate(kataB.length + 1, (i) => i);

  for (int i = 1; i <= kataA.length; i++) {
    List<int> barisSekarang = [i];
    for (int j = 1; j <= kataB.length; j++) {
      int biayaGanti = kataA[i - 1] == kataB[j - 1] ? 0 : 1;
      barisSekarang.add(
        min(
          min(barisSekarang[j - 1] + 1, barisSebelumnya[j] + 1),
          barisSebelumnya[j - 1] + biayaGanti,
        ),
      );
    }
    barisSebelumnya = barisSekarang;
  }

  return barisSebelumnya[kataB.length];
}

String? cariSaranEjaan(String kataKetikan, List<String> kamusFrasa) {
  String ketikanKecil = kataKetikan.trim().toLowerCase();
  if (ketikanKecil.length < 2) return null;

  int batasSalahKetik = max(1, ketikanKecil.length ~/ 3);
  String? frasaTerbaik;
  int jarakTerbaik = batasSalahKetik + 1;

  for (String frasa in kamusFrasa) {
    String frasaKecil = frasa.toLowerCase();
    List<String> bagianYangDibandingkan = [
      frasaKecil,
      ...frasaKecil.split(' ').where((kata) => kata.length >= 3),
    ];

    for (String bagian in bagianYangDibandingkan) {
      if ((bagian.length - ketikanKecil.length).abs() > batasSalahKetik) {
        continue;
      }

      int jarak = hitungJarakKetik(ketikanKecil, bagian);
      bool isLebihDekat = jarak < jarakTerbaik;
      bool isSamaDekatTapiLebihPendek =
          jarak == jarakTerbaik &&
          frasaTerbaik != null &&
          frasa.length < frasaTerbaik.length;

      if (jarak > 0 && (isLebihDekat || isSamaDekatTapiLebihPendek)) {
        jarakTerbaik = jarak;
        frasaTerbaik = frasa;
      }
    }
  }

  return frasaTerbaik;
}
