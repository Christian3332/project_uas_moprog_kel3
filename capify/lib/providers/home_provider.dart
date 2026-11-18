import 'package:flutter/material.dart';

import '../data/kategori_dummy.dart';
import '../data/lagu_per_kategori_dummy.dart';
import '../data/riwayat_putar_dummy.dart';
import '../models/kategori_musik.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';
import '../models/racikan_untukmu.dart';
import '../models/riwayat_putar.dart';
import '../utils/warna_capify.dart';

class HomeProvider extends ChangeNotifier {
  static const int batasJumlahRiwayat = 10;

  List<RiwayatPutar> _riwayatTerakhirDiputar = [];
  List<RacikanUntukmu> _daftarRacikanUntukmu = [];
  List<Lagu> _laguBelumPernahDidengar = [];
  bool _isSedangMemuat = false;
  bool _isSudahPernahDimuat = false;
  String? _pesanGagal;
  bool _isSudahDibuang = false;

  List<RiwayatPutar> get riwayatTerakhirDiputar =>
      List.unmodifiable(_riwayatTerakhirDiputar);
  List<RacikanUntukmu> get daftarRacikanUntukmu =>
      List.unmodifiable(_daftarRacikanUntukmu);
  List<Lagu> get laguBelumPernahDidengar =>
      List.unmodifiable(_laguBelumPernahDidengar);
  bool get isSedangMemuat => _isSedangMemuat;
  bool get isSudahPernahDimuat => _isSudahPernahDimuat;
  String? get pesanGagal => _pesanGagal;

  RiwayatPutar? get laguUntukDilanjutkan {
    if (_riwayatTerakhirDiputar.isEmpty) return null;
    return _riwayatTerakhirDiputar.first;
  }

  String _kunciLagu(Lagu lagu) => '${lagu.judul}|${lagu.penyanyi}';

  void _kabariPendengar() {
    if (_isSudahDibuang) return;
    notifyListeners();
  }

  Future<void> muatIsiBeranda({bool isPaksaMuatUlang = false}) async {
    if (_isSedangMemuat) return;
    if (_isSudahPernahDimuat && !isPaksaMuatUlang) return;

    _isSedangMemuat = true;
    _pesanGagal = null;
    _kabariPendengar();

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (!_isSudahPernahDimuat) {
        List<RiwayatPutar> riwayatDariYangTerbaru = List.of(
          daftarRiwayatPutarDummy,
        )..sort((a, b) => a.jarakSejakDiputar.compareTo(b.jarakSejakDiputar));
        _riwayatTerakhirDiputar = riwayatDariYangTerbaru
            .take(batasJumlahRiwayat)
            .toList();
      }

      _susunUlangRekomendasi();
      _isSudahPernahDimuat = true;
    } catch (error) {
      _pesanGagal = 'Beranda gagal dimuat, coba lagi sebentar ya';
    }

    _isSedangMemuat = false;
    _kabariPendengar();
  }

  void catatLaguDiputar(Lagu lagu) {
    String kunciLaguBaru = _kunciLagu(lagu);

    List<RiwayatPutar> riwayatBaru = [
      RiwayatPutar(lagu: lagu, jarakSejakDiputar: Duration.zero),
    ];
    for (RiwayatPutar riwayat in _riwayatTerakhirDiputar) {
      if (_kunciLagu(riwayat.lagu) != kunciLaguBaru) {
        riwayatBaru.add(riwayat);
      }
    }

    _riwayatTerakhirDiputar = riwayatBaru.take(batasJumlahRiwayat).toList();
    _susunUlangRekomendasi();
    _kabariPendengar();
  }

  void _susunUlangRekomendasi() {
    Set<String> laguYangPernahDiputar = _riwayatTerakhirDiputar
        .map((riwayat) => _kunciLagu(riwayat.lagu))
        .toSet();

    _daftarRacikanUntukmu = _racikPlaylistDariKategori(laguYangPernahDiputar);
    _laguBelumPernahDidengar = _cariLaguYangBelumDidengar(
      laguYangPernahDiputar,
    );
  }

  List<RacikanUntukmu> _racikPlaylistDariKategori(
    Set<String> laguYangPernahDiputar,
  ) {
    List<RacikanUntukmu> hasilRacikan = [];

    laguPerKategoriDummy.forEach((namaKategori, isiLagu) {
      if (isiLagu.isEmpty) return;

      int jumlahFamiliar = isiLagu
          .where((lagu) => laguYangPernahDiputar.contains(_kunciLagu(lagu)))
          .length;

      hasilRacikan.add(
        RacikanUntukmu(
          playlist: Playlist(
            nama: 'Racikan $namaKategori',
            deskripsi: _rangkumPenyanyi(isiLagu),
            daftarLagu: isiLagu,
          ),
          warnaAksen: _cariWarnaKategori(namaKategori),
          jumlahLaguFamiliar: jumlahFamiliar,
        ),
      );
    });

    List<RacikanUntukmu> urutanAwal = List.of(hasilRacikan);
    hasilRacikan.sort((a, b) {
      int selisihFamiliar = b.jumlahLaguFamiliar - a.jumlahLaguFamiliar;
      if (selisihFamiliar != 0) return selisihFamiliar;
      return urutanAwal.indexOf(a) - urutanAwal.indexOf(b);
    });

    return hasilRacikan;
  }

  String _rangkumPenyanyi(List<Lagu> isiLagu) {
    List<String> penyanyiTanpaDobel = [];
    for (Lagu lagu in isiLagu) {
      if (!penyanyiTanpaDobel.contains(lagu.penyanyi)) {
        penyanyiTanpaDobel.add(lagu.penyanyi);
      }
    }

    if (penyanyiTanpaDobel.length == 1) {
      return 'Spesial dari ${penyanyiTanpaDobel.first}';
    }
    if (penyanyiTanpaDobel.length == 2) {
      return '${penyanyiTanpaDobel[0]} dan ${penyanyiTanpaDobel[1]}';
    }
    return '${penyanyiTanpaDobel[0]}, ${penyanyiTanpaDobel[1]}, dan lainnya';
  }

  Color _cariWarnaKategori(String namaKategori) {
    for (KategoriMusik kategori in daftarKategoriDummy) {
      if (kategori.nama == namaKategori) return kategori.warnaKartu;
    }
    return WarnaCapify.coklatTua;
  }

  List<Lagu> _cariLaguYangBelumDidengar(Set<String> laguYangPernahDiputar) {
    List<Lagu> hasilTemuan = [];
    Set<String> laguYangSudahMasuk = {};

    for (List<Lagu> isiLagu in laguPerKategoriDummy.values) {
      for (Lagu lagu in isiLagu) {
        String kunci = _kunciLagu(lagu);
        bool isPernahDiputar = laguYangPernahDiputar.contains(kunci);
        bool isSudahMasukDaftar = laguYangSudahMasuk.contains(kunci);

        if (!isPernahDiputar && !isSudahMasukDaftar) {
          hasilTemuan.add(lagu);
          laguYangSudahMasuk.add(kunci);
        }
      }
    }

    return hasilTemuan;
  }

  @override
  void dispose() {
    _isSudahDibuang = true;
    super.dispose();
  }
}
