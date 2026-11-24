import 'package:flutter/material.dart';

import 'warna_capify.dart';

class GayaTeksBeranda {
  static const Color kremAgakRedup = Color(0xB8E1DCC9);
  static const Color kremRedup = Color(0xA6E1DCC9);

  static const TextStyle sapaanWaktu = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: WarnaCapify.krem,
  );

  static const TextStyle namaPengguna = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.15,
    color: WarnaCapify.putih,
  );

  static const TextStyle judulBagian = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
    color: WarnaCapify.putih,
  );

  static const TextStyle keteranganBagian = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: kremAgakRedup,
  );

  static const TextStyle tombolAksiBagian = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: WarnaCapify.krem,
  );

  static const TextStyle labelKecil = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: kremRedup,
  );
}
