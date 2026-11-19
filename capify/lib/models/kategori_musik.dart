import 'package:flutter/material.dart';

class KategoriMusik {
  final String nama;
  final IconData ikon;
  final Color warnaKartu;
  final String jenis;

  const KategoriMusik({
    required this.nama,
    required this.ikon,
    required this.warnaKartu,
    this.jenis = 'Genre',
  });
}
