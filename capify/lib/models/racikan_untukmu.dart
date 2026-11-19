import 'package:flutter/material.dart';

import 'playlist.dart';

class RacikanUntukmu {
  final String namaKategori;
  final Playlist playlist;
  final Color warnaAksen;
  final int jumlahLaguFamiliar;
  final bool isGenreFavorit;

  const RacikanUntukmu({
    required this.namaKategori,
    required this.playlist,
    required this.warnaAksen,
    required this.jumlahLaguFamiliar,
    this.isGenreFavorit = false,
  });
}
