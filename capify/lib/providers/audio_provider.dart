import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/lagu.dart';
import '../models/mode_ulang.dart';

class AudioProvider extends ChangeNotifier {
  List<Lagu> _antrianLagu = [];
  int _indexLaguSekarang = 0;
  String _namaAntrian = 'Lagu Pilihanmu';
  bool _isLaguSedangDiputar = false;
  bool _isSedangMemuat = false;
  bool _isAcak = false;
  ModeUlang _modeUlang = ModeUlang.mati;
  Duration _posisiSekarang = Duration.zero;
  final Set<String> _kunciLaguDisukai = {};

  Timer? _timerPemutar;
  int _nomorPermintaanPutar = 0;
  bool _isSudahDibuang = false;

  List<Lagu> get antrianLagu => List.unmodifiable(_antrianLagu);
  int get indexLaguSekarang => _indexLaguSekarang;
  String get namaAntrian => _namaAntrian;
  bool get isLaguSedangDiputar => _isLaguSedangDiputar;
  bool get isSedangMemuat => _isSedangMemuat;
  bool get isAcak => _isAcak;
  ModeUlang get modeUlang => _modeUlang;
  Duration get posisiSekarang => _posisiSekarang;

  Lagu? get laguSekarang {
    if (_antrianLagu.isEmpty) return null;
    return _antrianLagu[_indexLaguSekarang];
  }

  bool get isLaguSekarangDisukai {
    Lagu? lagu = laguSekarang;
    if (lagu == null) return false;
    return _kunciLaguDisukai.contains(_buatKunciLagu(lagu));
  }

  String _buatKunciLagu(Lagu lagu) => '${lagu.judul}|${lagu.penyanyi}';

  void _kabariPendengar() {
    if (_isSudahDibuang) return;
    notifyListeners();
  }

  void mulaiAntrian(
    List<Lagu> daftarLagu, {
    int indexMulai = 0,
    String namaAntrian = 'Lagu Pilihanmu',
    bool isLangsungDiputar = true,
  }) {
    if (daftarLagu.isEmpty) {
      _hentikanPemutar();
      _antrianLagu = [];
      _indexLaguSekarang = 0;
      _kabariPendengar();
      return;
    }

    int indexAman = indexMulai.clamp(0, daftarLagu.length - 1);
    Lagu laguYangDipilih = daftarLagu[indexAman];
    Lagu? laguSebelumnya = laguSekarang;
    bool isLaguYangSama =
        laguSebelumnya != null &&
        _buatKunciLagu(laguSebelumnya) == _buatKunciLagu(laguYangDipilih);

    _antrianLagu = List.of(daftarLagu);
    _indexLaguSekarang = indexAman;
    _namaAntrian = namaAntrian;

    if (!isLaguYangSama) {
      _posisiSekarang = Duration.zero;
    }
    _kabariPendengar();

    if (isLangsungDiputar && !_isLaguSedangDiputar) {
      putar();
    }
  }

  Future<void> putar() async {
    if (laguSekarang == null || _isSedangMemuat || _isLaguSedangDiputar) {
      return;
    }

    _nomorPermintaanPutar++;
    int nomorPermintaanIni = _nomorPermintaanPutar;

    _isSedangMemuat = true;
    _kabariPendengar();

    await Future.delayed(const Duration(milliseconds: 700));
    if (_isSudahDibuang || nomorPermintaanIni != _nomorPermintaanPutar) return;

    _isSedangMemuat = false;
    _isLaguSedangDiputar = true;
    _mulaiHitungWaktu();
    _kabariPendengar();
  }

  void jeda() {
    _hentikanPemutar();
    _kabariPendengar();
  }

  void togglePutarJeda() {
    if (_isSedangMemuat) return;
    if (_isLaguSedangDiputar) {
      jeda();
    } else {
      putar();
    }
  }

  void _hentikanPemutar() {
    _nomorPermintaanPutar++;
    _timerPemutar?.cancel();
    _timerPemutar = null;
    _isLaguSedangDiputar = false;
    _isSedangMemuat = false;
  }

  void _mulaiHitungWaktu() {
    _timerPemutar?.cancel();
    _timerPemutar = Timer.periodic(const Duration(seconds: 1), (_) {
      Lagu? lagu = laguSekarang;
      if (lagu == null) return;

      Duration posisiBerikutnya = _posisiSekarang + const Duration(seconds: 1);
      if (posisiBerikutnya >= lagu.durasi) {
        _laguSudahHabis();
        return;
      }
      _posisiSekarang = posisiBerikutnya;
      _kabariPendengar();
    });
  }

  void _laguSudahHabis() {
    if (_modeUlang == ModeUlang.satu) {
      _posisiSekarang = Duration.zero;
      _kabariPendengar();
      return;
    }
    laguBerikutnya();
  }

  int? _cariIndexBerikutnya() {
    int jumlahLagu = _antrianLagu.length;
    if (jumlahLagu == 0) return null;

    if (_isAcak && jumlahLagu > 1) {
      int indexAcak = _indexLaguSekarang;
      while (indexAcak == _indexLaguSekarang) {
        indexAcak = Random().nextInt(jumlahLagu);
      }
      return indexAcak;
    }

    if (_indexLaguSekarang + 1 < jumlahLagu) return _indexLaguSekarang + 1;
    if (_modeUlang == ModeUlang.semua) return 0;
    return null;
  }

  bool laguBerikutnya() {
    if (laguSekarang == null) return false;

    int? indexBerikutnya = _cariIndexBerikutnya();
    if (indexBerikutnya == null) {
      _hentikanPemutar();
      _posisiSekarang = Duration.zero;
      _kabariPendengar();
      return false;
    }

    _gantiLagu(indexBerikutnya);
    return true;
  }

  void laguSebelumnya() {
    if (laguSekarang == null) return;

    bool sudahLewatTigaDetik = _posisiSekarang.inSeconds > 3;
    if (sudahLewatTigaDetik || _indexLaguSekarang == 0) {
      _posisiSekarang = Duration.zero;
      _kabariPendengar();
      return;
    }
    _gantiLagu(_indexLaguSekarang - 1);
  }

  void _gantiLagu(int indexBaru) {
    _indexLaguSekarang = indexBaru;
    _posisiSekarang = Duration.zero;
    _kabariPendengar();
  }

  void geserKe(Duration posisiTujuan) {
    Lagu? lagu = laguSekarang;
    if (lagu == null) return;

    if (posisiTujuan < Duration.zero) {
      _posisiSekarang = Duration.zero;
    } else if (posisiTujuan > lagu.durasi) {
      _posisiSekarang = lagu.durasi;
    } else {
      _posisiSekarang = posisiTujuan;
    }
    _kabariPendengar();
  }

  void toggleAcak() {
    _isAcak = !_isAcak;
    _kabariPendengar();
  }

  void gantiModeUlang() {
    int indexModeBaru = (_modeUlang.index + 1) % ModeUlang.values.length;
    _modeUlang = ModeUlang.values[indexModeBaru];
    _kabariPendengar();
  }

  void toggleSukaiLaguSekarang() {
    Lagu? lagu = laguSekarang;
    if (lagu == null) return;

    String kunci = _buatKunciLagu(lagu);
    if (_kunciLaguDisukai.contains(kunci)) {
      _kunciLaguDisukai.remove(kunci);
    } else {
      _kunciLaguDisukai.add(kunci);
    }
    _kabariPendengar();
  }

  @override
  void dispose() {
    _isSudahDibuang = true;
    _timerPemutar?.cancel();
    super.dispose();
  }
}
