import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/lagu.dart';
import '../models/mode_ulang.dart';
import '../utils/kunci_lagu.dart';

class AudioProvider extends ChangeNotifier {
  static const String urlAudioCadangan =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  AudioProvider({
    AudioPlayer? pemutarAudio,
    this.batasWaktuMemuat = const Duration(seconds: 20),
  }) : _pemutar = pemutarAudio;

  final Duration batasWaktuMemuat;
  AudioPlayer? _pemutar;
  final List<StreamSubscription> _langgananStream = [];
  final List<StreamSubscription> _langgananSesiAudio = [];
  bool _isDijedaKarenaInterupsi = false;
  String? _pesanInterupsi;

  List<Lagu> _antrianLagu = [];
  int _indexLaguSekarang = 0;
  List<int> _urutanPutar = [];
  int _posisiDiUrutan = 0;
  final Random _pengacak = Random();
  String _namaAntrian = 'Lagu Pilihanmu';
  bool _isLaguSedangDiputar = false;
  bool _isSedangMenyiapkanLagu = false;
  bool _isSedangBuffering = false;
  bool _isAcak = false;
  ModeUlang _modeUlang = ModeUlang.mati;
  Duration _posisiSekarang = Duration.zero;
  Duration _posisiTerbuffer = Duration.zero;
  Duration? _durasiDariAudio;
  String? _pesanError;

  Lagu? _laguYangSudahDimuat;
  int _nomorPermintaanMuat = 0;
  bool _isSudahDibuang = false;
  bool _isPemutaranDiizinkan = true;
  int _jumlahPutarDitolak = 0;

  List<Lagu> get antrianLagu => List.unmodifiable(_antrianLagu);
  int get indexLaguSekarang => _indexLaguSekarang;
  String get namaAntrian => _namaAntrian;
  bool get isLaguSedangDiputar => _isLaguSedangDiputar;
  bool get isPemutaranDiizinkan => _isPemutaranDiizinkan;
  int get jumlahPutarDitolak => _jumlahPutarDitolak;
  bool get isSedangMemuat => _isSedangMenyiapkanLagu || _isSedangBuffering;
  bool get isSedangMenyiapkanLagu => _isSedangMenyiapkanLagu;
  bool get isSedangBuffering => _isSedangBuffering && !_isSedangMenyiapkanLagu;
  bool get isAcak => _isAcak;
  ModeUlang get modeUlang => _modeUlang;
  Duration get posisiSekarang => _posisiSekarang;
  Duration get posisiTerbuffer => _posisiTerbuffer;
  String? get pesanError => _pesanError;
  String? get pesanInterupsi => _pesanInterupsi;

  Lagu? get laguSekarang {
    if (_antrianLagu.isEmpty) return null;
    return _antrianLagu[_indexLaguSekarang];
  }

  Duration get durasiLaguSekarang {
    Lagu? lagu = laguSekarang;
    if (lagu == null) return Duration.zero;
    return _durasiDariAudio ?? lagu.durasi;
  }

  bool get _isLaguSekarangSudahDimuat {
    Lagu? lagu = laguSekarang;
    return lagu != null && identical(lagu, _laguYangSudahDimuat);
  }

  static Future<void> siapkanPemutaranBackground() async {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.example.capify.channel.audio',
        androidNotificationChannelName: 'Pemutaran Musik Capify',
        androidNotificationOngoing: true,
      );
    } catch (_) {}
  }

  Future<void> siapkanSesiAudio() async {
    try {
      AudioSession sesi = await AudioSession.instance;
      await sesi.configure(const AudioSessionConfiguration.music());
      _langgananSesiAudio.add(
        sesi.interruptionEventStream.listen(saatAdaInterupsi),
      );
      _langgananSesiAudio.add(
        sesi.becomingNoisyEventStream.listen((_) => saatHeadsetDicabut()),
      );
    } catch (_) {}
  }

  void saatAdaInterupsi(AudioInterruptionEvent interupsi) {
    if (interupsi.type == AudioInterruptionType.duck) {
      _pemutar?.setVolume(interupsi.begin ? 0.3 : 1.0);
      return;
    }

    if (interupsi.begin) {
      if (!_isLaguSedangDiputar && !_isSedangMenyiapkanLagu) return;
      _jedaPemutar();
      _isDijedaKarenaInterupsi = true;
      _pesanInterupsi =
          'Lagu dijeda sementara karena ada panggilan atau suara lain';
      _kabariPendengar();
      return;
    }

    if (!_isDijedaKarenaInterupsi) return;
    _isDijedaKarenaInterupsi = false;

    if (interupsi.type == AudioInterruptionType.pause) {
      _pesanInterupsi = null;
      putar();
    } else {
      _pesanInterupsi = 'Gangguan sudah selesai, ketuk play untuk melanjutkan';
      _kabariPendengar();
    }
  }

  void saatHeadsetDicabut() {
    if (!_isLaguSedangDiputar) return;
    _jedaPemutar();
    _isDijedaKarenaInterupsi = false;
    _pesanInterupsi = 'Headset terlepas, lagu dijeda';
    _kabariPendengar();
  }

  void _hapusStatusInterupsi() {
    _isDijedaKarenaInterupsi = false;
    _pesanInterupsi = null;
  }

  String _ambilUrlAudio(Lagu lagu) {
    String urlAudio = lagu.urlAudio.trim();
    return urlAudio.isEmpty ? urlAudioCadangan : urlAudio;
  }

  void _kabariPendengar() {
    if (_isSudahDibuang) return;
    notifyListeners();
  }

  AudioPlayer _ambilPemutar() {
    AudioPlayer pemutar = _pemutar ?? AudioPlayer(handleInterruptions: false);
    _pemutar = pemutar;

    if (_langgananStream.isEmpty) {
      _langgananStream.add(
        pemutar.playerStateStream.listen(_saatStatusPemutarBerubah),
      );
      _langgananStream.add(pemutar.positionStream.listen(_saatPosisiBerubah));
      _langgananStream.add(pemutar.durationStream.listen(_saatDurasiDidapat));
      _langgananStream.add(
        pemutar.bufferedPositionStream.listen(_saatPosisiTerbufferBerubah),
      );
      _langgananStream.add(pemutar.errorStream.listen(_saatTerjadiError));
    }
    return pemutar;
  }

  String _buatPesanError(Object error) {
    if (error is TimeoutException) {
      return 'Koneksi terlalu lambat, lagu belum bisa dimuat';
    }
    if (error is PlayerException) {
      return 'Lagu gagal dimuat. Cek koneksi internetmu lalu coba lagi';
    }
    return 'Terjadi kesalahan saat memutar lagu';
  }

  void _saatPosisiTerbufferBerubah(Duration posisiBaru) {
    if (!_isLaguSekarangSudahDimuat) return;

    bool isDetiknyaBerubah = posisiBaru.inSeconds != _posisiTerbuffer.inSeconds;
    _posisiTerbuffer = posisiBaru;
    if (isDetiknyaBerubah) {
      _kabariPendengar();
    }
  }

  void _saatTerjadiError(PlayerException error) {
    if (_isSedangMenyiapkanLagu) return;

    _isLaguSedangDiputar = false;
    _isSedangBuffering = false;
    _laguYangSudahDimuat = null;
    _pesanError = _buatPesanError(error);
    _kabariPendengar();
  }

  void _saatStatusPemutarBerubah(PlayerState status) {
    if (status.processingState == ProcessingState.completed) {
      bool isLaguIniBenarSelesai =
          status.playing &&
          _isLaguSekarangSudahDimuat &&
          !_isSedangMenyiapkanLagu;
      if (isLaguIniBenarSelesai) {
        _laguSudahHabis();
      }
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
    _hapusStatusInterupsi();
    _durasiDariAudio = null;
    _posisiTerbuffer = Duration.zero;
    _laguYangSudahDimuat = null;
    _kabariPendengar();

    try {
      AudioPlayer pemutar = _ambilPemutar();
      Duration posisiSaatMulaiMuat = _posisiSekarang;
      Duration? durasiAsli = await pemutar
          .setUrl(
            _ambilUrlAudio(lagu),
            initialPosition: posisiSaatMulaiMuat,
            tag: _buatInfoNotifikasi(lagu),
          )
          .timeout(batasWaktuMemuat);
      if (_isSudahDibuang || nomorPermintaanIni != _nomorPermintaanMuat) {
        return;
      }

      bool isDigeserSaatMemuat = _posisiSekarang != posisiSaatMulaiMuat;
      if (isDigeserSaatMemuat) {
        await pemutar.seek(_posisiSekarang);
        if (_isSudahDibuang || nomorPermintaanIni != _nomorPermintaanMuat) {
          return;
        }
      }

      _laguYangSudahDimuat = lagu;
      _durasiDariAudio = durasiAsli;
      _isSedangMenyiapkanLagu = false;
      _kabariPendengar();

      if (isLangsungDiputar) {
        _mulaiPutarDiPemutar();
      }
    } catch (error) {
      if (_isSudahDibuang || nomorPermintaanIni != _nomorPermintaanMuat) {
        return;
      }
      if (error is TimeoutException) {
        _pemutar?.stop();
      }
      _isSedangMenyiapkanLagu = false;
      _isSedangBuffering = false;
      _isLaguSedangDiputar = false;
      _pesanError = _buatPesanError(error);
      _kabariPendengar();
    }
  }

  void aturIzinPemutaran(bool isDiizinkan) {
    if (_isPemutaranDiizinkan == isDiizinkan) return;
    _isPemutaranDiizinkan = isDiizinkan;
    if (!isDiizinkan) jeda();
  }

  bool mintaIzinPemutaran() {
    if (_isPemutaranDiizinkan) return true;
    _jumlahPutarDitolak++;
    _kabariPendengar();
    return false;
  }

  void cobaLagi() {
    if (laguSekarang == null || _isSedangMenyiapkanLagu) return;
    if (!mintaIzinPemutaran()) return;
    _muatLaguSekarang(isLangsungDiputar: true);
  }

  void _mulaiPutarDiPemutar() {
    AudioPlayer? pemutar = _pemutar;
    if (pemutar == null) return;

    _isLaguSedangDiputar = true;
    _kabariPendengar();
    pemutar.play().catchError((Object error) {
      _isLaguSedangDiputar = false;
      _laguYangSudahDimuat = null;
      _pesanError = _buatPesanError(error);
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
      _susunUrutanPutar();
      _kabariPendengar();
      return;
    }

    bool isBolehLangsungDiputar = isLangsungDiputar && mintaIzinPemutaran();
    int indexAman = indexMulai.clamp(0, daftarLagu.length - 1);
    Lagu laguYangDipilih = daftarLagu[indexAman];
    Lagu? laguSebelumnya = laguSekarang;
    bool isLaguYangSama =
        laguSebelumnya != null &&
        kunciUnikLagu(laguSebelumnya) == kunciUnikLagu(laguYangDipilih);
    bool isTadiSedangDiputar = _isLaguSedangDiputar || _isSedangMenyiapkanLagu;

    if (isLaguYangSama && _laguYangSudahDimuat != null) {
      _laguYangSudahDimuat = laguYangDipilih;
    }

    _antrianLagu = List.of(daftarLagu);
    _indexLaguSekarang = indexAman;
    _namaAntrian = namaAntrian;
    _susunUrutanPutar();

    if (isLaguYangSama) {
      _kabariPendengar();
      if (isBolehLangsungDiputar && !isTadiSedangDiputar) {
        putar();
      }
      return;
    }

    _posisiSekarang = Duration.zero;
    _posisiTerbuffer = Duration.zero;
    _durasiDariAudio = null;
    _pesanError = null;
    _kabariPendengar();

    if (isBolehLangsungDiputar || isTadiSedangDiputar) {
      _muatLaguSekarang(isLangsungDiputar: true);
    }
  }

  MediaItem _buatInfoNotifikasi(Lagu lagu) {
    String urlCover = lagu.urlCover.trim();
    return MediaItem(
      id: '${kunciUnikLagu(lagu)}|$_indexLaguSekarang',
      title: lagu.judul,
      artist: lagu.penyanyi,
      album: _namaAntrian,
      duration: lagu.durasi,
      artUri: urlCover.isEmpty ? null : Uri.tryParse(urlCover),
    );
  }

  Future<void> putar() async {
    if (laguSekarang == null || _isSedangMenyiapkanLagu) return;
    if (!mintaIzinPemutaran()) return;
    _hapusStatusInterupsi();

    if (_isLaguSekarangSudahDimuat) {
      _pesanError = null;
      _mulaiPutarDiPemutar();
      return;
    }
    await _muatLaguSekarang(isLangsungDiputar: true);
  }

  void _jedaPemutar() {
    _nomorPermintaanMuat++;
    _isSedangMenyiapkanLagu = false;
    _isLaguSedangDiputar = false;
    _pemutar?.pause();
  }

  void jeda() {
    _hapusStatusInterupsi();
    _jedaPemutar();
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

  void _susunUrutanPutar() {
    int jumlahLagu = _antrianLagu.length;
    List<int> semuaIndex = List.generate(jumlahLagu, (index) => index);

    if (!_isAcak) {
      _urutanPutar = semuaIndex;
      _posisiDiUrutan = _indexLaguSekarang;
      return;
    }

    List<int> sisaLagu = semuaIndex
      ..remove(_indexLaguSekarang)
      ..shuffle(_pengacak);
    _urutanPutar = [_indexLaguSekarang, ...sisaLagu];
    _posisiDiUrutan = 0;
  }

  void _acakUlangUntukPutaranBaru() {
    List<int> urutanBaru = List.generate(_antrianLagu.length, (index) => index)
      ..shuffle(_pengacak);

    bool isLaguSamaDiAwal =
        urutanBaru.length > 1 && urutanBaru.first == _indexLaguSekarang;
    if (isLaguSamaDiAwal) {
      urutanBaru[0] = urutanBaru.last;
      urutanBaru[urutanBaru.length - 1] = _indexLaguSekarang;
    }
    _urutanPutar = urutanBaru;
  }

  bool laguBerikutnya() {
    if (laguSekarang == null) return false;

    int posisiBerikutnya = _posisiDiUrutan + 1;
    bool isAntrianHabis = posisiBerikutnya >= _urutanPutar.length;

    if (isAntrianHabis) {
      if (_modeUlang != ModeUlang.semua) {
        _berhentiDanKembaliKeAwal();
        _kabariPendengar();
        return false;
      }
      if (_isAcak) {
        _acakUlangUntukPutaranBaru();
      }
      posisiBerikutnya = 0;
    }

    _posisiDiUrutan = posisiBerikutnya;
    _gantiLagu(_urutanPutar[posisiBerikutnya]);
    return true;
  }

  void laguSebelumnya() {
    if (laguSekarang == null) return;

    bool sudahLewatTigaDetik = _posisiSekarang.inSeconds > 3;
    if (sudahLewatTigaDetik || _posisiDiUrutan == 0) {
      geserKe(Duration.zero);
      return;
    }

    _posisiDiUrutan--;
    _gantiLagu(_urutanPutar[_posisiDiUrutan]);
  }

  void _gantiLagu(int indexBaru) {
    bool isTadiSedangDiputar = _isLaguSedangDiputar || _isSedangMenyiapkanLagu;

    _indexLaguSekarang = indexBaru;
    _posisiSekarang = Duration.zero;
    _posisiTerbuffer = Duration.zero;
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
    _susunUrutanPutar();
    _kabariPendengar();
  }

  void gantiModeUlang() {
    int indexModeBaru = (_modeUlang.index + 1) % ModeUlang.values.length;
    _modeUlang = ModeUlang.values[indexModeBaru];
    _kabariPendengar();
  }

  @override
  void dispose() {
    _isSudahDibuang = true;
    for (StreamSubscription langganan in _langgananStream) {
      langganan.cancel();
    }
    for (StreamSubscription langganan in _langgananSesiAudio) {
      langganan.cancel();
    }
    _pemutar?.dispose();
    super.dispose();
  }
}
