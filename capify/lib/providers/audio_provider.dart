import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/lagu.dart';
import '../models/mode_ulang.dart';

class AudioProvider extends ChangeNotifier {
  static const String urlAudioCadangan =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  AudioProvider({AudioPlayer? pemutarAudio}) : _pemutar = pemutarAudio;

  AudioPlayer? _pemutar;
  final List<StreamSubscription> _langgananStream = [];

  List<Lagu> _antrianLagu = [];
  int _indexLaguSekarang = 0;
  String _namaAntrian = 'Lagu Pilihanmu';
  bool _isLaguSedangDiputar = false;
  bool _isSedangMenyiapkanLagu = false;
  bool _isSedangBuffering = false;
  bool _isAcak = false;
  ModeUlang _modeUlang = ModeUlang.mati;
  Duration _posisiSekarang = Duration.zero;
  Duration? _durasiDariAudio;
  String? _pesanError;
  final Set<String> _kunciLaguDisukai = {};

  Lagu? _laguYangSudahDimuat;
  int _nomorPermintaanMuat = 0;
  bool _isSudahDibuang = false;

  List<Lagu> get antrianLagu => List.unmodifiable(_antrianLagu);
  int get indexLaguSekarang => _indexLaguSekarang;
  String get namaAntrian => _namaAntrian;
  bool get isLaguSedangDiputar => _isLaguSedangDiputar;
  bool get isSedangMemuat => _isSedangMenyiapkanLagu || _isSedangBuffering;
  bool get isAcak => _isAcak;
  ModeUlang get modeUlang => _modeUlang;
  Duration get posisiSekarang => _posisiSekarang;
  String? get pesanError => _pesanError;

  Lagu? get laguSekarang {
    if (_antrianLagu.isEmpty) return null;
    return _antrianLagu[_indexLaguSekarang];
  }

  Duration get durasiLaguSekarang {
    Lagu? lagu = laguSekarang;
    if (lagu == null) return Duration.zero;
    return _durasiDariAudio ?? lagu.durasi;
  }

  bool get isLaguSekarangDisukai {
    Lagu? lagu = laguSekarang;
    if (lagu == null) return false;
    return _kunciLaguDisukai.contains(_buatKunciLagu(lagu));
  }

  bool get _isLaguSekarangSudahDimuat {
    Lagu? lagu = laguSekarang;
    return lagu != null && identical(lagu, _laguYangSudahDimuat);
  }

  String _buatKunciLagu(Lagu lagu) => '${lagu.judul}|${lagu.penyanyi}';

  String _ambilUrlAudio(Lagu lagu) {
    String urlAudio = lagu.urlAudio.trim();
    return urlAudio.isEmpty ? urlAudioCadangan : urlAudio;
  }

  void _kabariPendengar() {
    if (_isSudahDibuang) return;
    notifyListeners();
  }

  AudioPlayer _ambilPemutar() {
    AudioPlayer pemutar = _pemutar ?? AudioPlayer();
    _pemutar = pemutar;

    if (_langgananStream.isEmpty) {
      _langgananStream.add(
        pemutar.playerStateStream.listen(_saatStatusPemutarBerubah),
      );
      _langgananStream.add(pemutar.positionStream.listen(_saatPosisiBerubah));
      _langgananStream.add(pemutar.durationStream.listen(_saatDurasiDidapat));
    }
    return pemutar;
  }

  void _saatStatusPemutarBerubah(PlayerState status) {
    if (status.processingState == ProcessingState.completed) {
      _laguSudahHabis();
      return;
    }

    _isLaguSedangDiputar = status.playing;
    _isSedangBuffering =
        status.processingState == ProcessingState.loading ||
        status.processingState == ProcessingState.buffering;
    _kabariPendengar();
  }

  void _saatPosisiBerubah(Duration posisiBaru) {
    if (!_isLaguSekarangSudahDimuat || _isSedangMenyiapkanLagu) return;

    bool isDetiknyaBerubah = posisiBaru.inSeconds != _posisiSekarang.inSeconds;
    _posisiSekarang = posisiBaru;
    if (isDetiknyaBerubah) {
      _kabariPendengar();
    }
  }

  void _saatDurasiDidapat(Duration? durasiBaru) {
    if (durasiBaru == null || !_isLaguSekarangSudahDimuat) return;
    _durasiDariAudio = durasiBaru;
    _kabariPendengar();
  }

  Future<void> _muatLaguSekarang({required bool isLangsungDiputar}) async {
    Lagu? lagu = laguSekarang;
    if (lagu == null) return;

    _nomorPermintaanMuat++;
    int nomorPermintaanIni = _nomorPermintaanMuat;

    _isSedangMenyiapkanLagu = true;
    _pesanError = null;
    _durasiDariAudio = null;
    _laguYangSudahDimuat = null;
    _kabariPendengar();

    try {
      AudioPlayer pemutar = _ambilPemutar();
      Duration? durasiAsli = await pemutar.setUrl(
        _ambilUrlAudio(lagu),
        initialPosition: _posisiSekarang,
      );
      if (_isSudahDibuang || nomorPermintaanIni != _nomorPermintaanMuat) {
        return;
      }

      _laguYangSudahDimuat = lagu;
      _durasiDariAudio = durasiAsli;
      _isSedangMenyiapkanLagu = false;
      _kabariPendengar();

      if (isLangsungDiputar) {
        _mulaiPutarDiPemutar();
      }
    } catch (_) {
      if (_isSudahDibuang || nomorPermintaanIni != _nomorPermintaanMuat) {
        return;
      }
      _isSedangMenyiapkanLagu = false;
      _isLaguSedangDiputar = false;
      _pesanError = 'Lagu gagal diputar. Cek koneksi internetmu lalu coba lagi';
      _kabariPendengar();
    }
  }

  void _mulaiPutarDiPemutar() {
    AudioPlayer? pemutar = _pemutar;
    if (pemutar == null) return;

    _isLaguSedangDiputar = true;
    _kabariPendengar();
    pemutar.play().catchError((Object _) {
      _isLaguSedangDiputar = false;
      _pesanError = 'Lagu gagal diputar. Coba lagi sebentar lagi';
      _kabariPendengar();
    });
  }

  void mulaiAntrian(
    List<Lagu> daftarLagu, {
    int indexMulai = 0,
    String namaAntrian = 'Lagu Pilihanmu',
    bool isLangsungDiputar = true,
  }) {
    if (daftarLagu.isEmpty) {
      _berhentiDanKembaliKeAwal();
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
    bool isTadiSedangDiputar = _isLaguSedangDiputar || _isSedangMenyiapkanLagu;

    if (isLaguYangSama && _laguYangSudahDimuat != null) {
      _laguYangSudahDimuat = laguYangDipilih;
    }

    _antrianLagu = List.of(daftarLagu);
    _indexLaguSekarang = indexAman;
    _namaAntrian = namaAntrian;

    if (isLaguYangSama) {
      _kabariPendengar();
      if (isLangsungDiputar && !isTadiSedangDiputar) {
        putar();
      }
      return;
    }

    _posisiSekarang = Duration.zero;
    _durasiDariAudio = null;
    _pesanError = null;
    _kabariPendengar();

    if (isLangsungDiputar || isTadiSedangDiputar) {
      _muatLaguSekarang(isLangsungDiputar: true);
    }
  }

  Future<void> putar() async {
    if (laguSekarang == null || _isSedangMenyiapkanLagu) return;

    if (_isLaguSekarangSudahDimuat) {
      _pesanError = null;
      _mulaiPutarDiPemutar();
      return;
    }
    await _muatLaguSekarang(isLangsungDiputar: true);
  }

  void jeda() {
    _nomorPermintaanMuat++;
    _isSedangMenyiapkanLagu = false;
    _isLaguSedangDiputar = false;
    _pemutar?.pause();
    _kabariPendengar();
  }

  void togglePutarJeda() {
    if (_isLaguSedangDiputar) {
      jeda();
    } else {
      putar();
    }
  }

  void _berhentiDanKembaliKeAwal() {
    _nomorPermintaanMuat++;
    _isSedangMenyiapkanLagu = false;
    _isLaguSedangDiputar = false;
    _posisiSekarang = Duration.zero;
    _pemutar?.pause();
    if (_isLaguSekarangSudahDimuat) {
      _pemutar?.seek(Duration.zero);
    }
  }

  void _laguSudahHabis() {
    if (_modeUlang == ModeUlang.satu) {
      _posisiSekarang = Duration.zero;
      _pemutar?.seek(Duration.zero);
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
      _berhentiDanKembaliKeAwal();
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
      geserKe(Duration.zero);
      return;
    }
    _gantiLagu(_indexLaguSekarang - 1);
  }

  void _gantiLagu(int indexBaru) {
    bool isTadiSedangDiputar = _isLaguSedangDiputar || _isSedangMenyiapkanLagu;

    _indexLaguSekarang = indexBaru;
    _posisiSekarang = Duration.zero;
    _durasiDariAudio = null;
    _pesanError = null;

    if (isTadiSedangDiputar) {
      _muatLaguSekarang(isLangsungDiputar: true);
    } else {
      _nomorPermintaanMuat++;
      _kabariPendengar();
    }
  }

  void geserKe(Duration posisiTujuan) {
    if (laguSekarang == null) return;

    Duration batasAkhir = durasiLaguSekarang;
    if (posisiTujuan < Duration.zero) {
      _posisiSekarang = Duration.zero;
    } else if (posisiTujuan > batasAkhir) {
      _posisiSekarang = batasAkhir;
    } else {
      _posisiSekarang = posisiTujuan;
    }

    if (_isLaguSekarangSudahDimuat) {
      _pemutar?.seek(_posisiSekarang);
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
    for (StreamSubscription langganan in _langgananStream) {
      langganan.cancel();
    }
    _pemutar?.dispose();
    super.dispose();
  }
}
