import 'dart:async';

import 'package:flutter/material.dart';

import '../data/kategori_dummy.dart';
import '../models/feed_beranda.dart';
import '../models/kategori_musik.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';
import '../models/racikan_untukmu.dart';
import '../models/riwayat_putar.dart';
import '../services/feed_service.dart';
import '../utils/warna_capify.dart';
import 'audio_provider.dart';

class HomeProvider extends ChangeNotifier {
  static const int batasJumlahRiwayat = 10;
  static const int batasGenreFavorit = 5;

  final FeedService feedService;
  final Duration batasSabarMenunggu;

  HomeProvider({
    this.feedService = const FeedService(),
    this.batasSabarMenunggu = const Duration(seconds: 4),
  });

  Map<String, List<Lagu>> _laguPerGenre = {};
  List<RiwayatPutar> _riwayatTerakhirDiputar = [];
  List<RacikanUntukmu> _daftarRacikanUntukmu = [];
  List<Lagu> _laguBelumPernahDidengar = [];
  bool _isSedangMemuat = false;
  bool _isSudahPernahDimuat = false;
  String? _pesanGagal;
  bool _isMemakaiDataCadangan = false;
  bool _isMemuatTerlaluLama = false;
  Timer? _timerPenandaLambat;
  bool _isSudahDibuang = false;

  AudioProvider? _pemutarYangDipantau;
  String? _kunciLaguTerakhirDicatat;
  List<String> _genreFavorit = [];

  List<RiwayatPutar> get riwayatTerakhirDiputar =>
      List.unmodifiable(_riwayatTerakhirDiputar);
  List<RacikanUntukmu> get daftarRacikanUntukmu =>
      List.unmodifiable(_daftarRacikanUntukmu);
  List<Lagu> get laguBelumPernahDidengar =>
      List.unmodifiable(_laguBelumPernahDidengar);
  bool get isSedangMemuat => _isSedangMemuat;
  bool get isSudahPernahDimuat => _isSudahPernahDimuat;
  String? get pesanGagal => _pesanGagal;
  bool get isMemakaiDataCadangan => _isMemakaiDataCadangan;
  bool get isMemuatTerlaluLama => _isMemuatTerlaluLama;
  bool get isSedangMenyegarkan => _isSedangMemuat && _isSudahPernahDimuat;
  bool get isMuatPertamaKali => !_isSudahPernahDimuat && _pesanGagal == null;
  List<String> get genreFavorit => List.unmodifiable(_genreFavorit);
  bool get isSudahPilihGenre => _genreFavorit.isNotEmpty;

  RiwayatPutar? get laguUntukDilanjutkan {
    if (_riwayatTerakhirDiputar.isEmpty) return null;
    return _riwayatTerakhirDiputar.first;
  }

  String kunciLagu(Lagu lagu) => '${lagu.judul}|${lagu.penyanyi}';

  void _kabariPendengar() {
    if (_isSudahDibuang) return;
    notifyListeners();
  }

  void pantauPemutar(AudioProvider pemutar) {
    if (identical(_pemutarYangDipantau, pemutar)) return;

    _pemutarYangDipantau?.removeListener(_cekLaguYangSedangDiputar);
    _pemutarYangDipantau = pemutar;
    pemutar.addListener(_cekLaguYangSedangDiputar);
    _cekLaguYangSedangDiputar();
  }

  void _cekLaguYangSedangDiputar() {
    AudioProvider? pemutar = _pemutarYangDipantau;
    if (pemutar == null || !pemutar.isLaguSedangDiputar) return;

    Lagu? laguYangDiputar = pemutar.laguSekarang;
    if (laguYangDiputar == null) return;
    if (kunciLagu(laguYangDiputar) == _kunciLaguTerakhirDicatat) return;

    catatLaguDiputar(laguYangDiputar);
  }

  Future<void> muatIsiBeranda({bool isPaksaMuatUlang = false}) async {
    if (_isSedangMemuat) return;
    if (_isSudahPernahDimuat && !isPaksaMuatUlang) return;

    _isSedangMemuat = true;
    _pesanGagal = null;
    _mulaiHitungKesabaran();
    _kabariPendengar();

    try {
      FeedBeranda feedDariServer = await feedService.ambilFeedBeranda();
      if (_isSudahDibuang) return;

      _laguPerGenre = feedDariServer.laguPerGenre;
      _isMemakaiDataCadangan = feedDariServer.isDariCadangan;
      _gabungkanDenganRiwayatServer(feedDariServer.riwayatPutar);
      _susunUlangRekomendasi();
      _isSudahPernahDimuat = true;
    } catch (error) {
      _pesanGagal = _rapikanPesanGagal(error);
    }

    _hentikanHitungKesabaran();
    _isSedangMemuat = false;
    _kabariPendengar();
  }

  void _mulaiHitungKesabaran() {
    _timerPenandaLambat?.cancel();
    _isMemuatTerlaluLama = false;
    _timerPenandaLambat = Timer(batasSabarMenunggu, () {
      if (!_isSedangMemuat) return;
      _isMemuatTerlaluLama = true;
      _kabariPendengar();
    });
  }

  void _hentikanHitungKesabaran() {
    _timerPenandaLambat?.cancel();
    _timerPenandaLambat = null;
    _isMemuatTerlaluLama = false;
  }

  String _rapikanPesanGagal(Object error) {
    String pesanAsli = error.toString().replaceFirst('Exception: ', '').trim();
    if (pesanAsli.isEmpty) return 'Beranda gagal dimuat, coba lagi sebentar ya';
    return pesanAsli;
  }

  void _gabungkanDenganRiwayatServer(List<RiwayatPutar> riwayatDariServer) {
    List<RiwayatPutar> riwayatServerTerbaru = List.of(riwayatDariServer)
      ..sort((a, b) => a.jarakSejakDiputar.compareTo(b.jarakSejakDiputar));

    Set<String> laguYangSudahDicatat = _riwayatTerakhirDiputar
        .map((riwayat) => kunciLagu(riwayat.lagu))
        .toSet();

    List<RiwayatPutar> riwayatGabungan = [
      ..._riwayatTerakhirDiputar,
      ...riwayatServerTerbaru.where(
        (riwayat) => !laguYangSudahDicatat.contains(kunciLagu(riwayat.lagu)),
      ),
    ];

    _riwayatTerakhirDiputar = riwayatGabungan.take(batasJumlahRiwayat).toList();
  }

  void catatLaguDiputar(Lagu lagu) {
    String kunciLaguBaru = kunciLagu(lagu);
    _kunciLaguTerakhirDicatat = kunciLaguBaru;

    List<RiwayatPutar> riwayatBaru = [
      RiwayatPutar(lagu: lagu, jarakSejakDiputar: Duration.zero),
    ];
    for (RiwayatPutar riwayat in _riwayatTerakhirDiputar) {
      if (kunciLagu(riwayat.lagu) != kunciLaguBaru) {
        riwayatBaru.add(riwayat);
      }
    }

    _riwayatTerakhirDiputar = riwayatBaru.take(batasJumlahRiwayat).toList();
    _susunUlangRekomendasi();
    _kabariPendengar();
  }

  void simpanGenreFavorit(List<String> genrePilihan) {
    Set<String> namaGenreYangAda = daftarKategoriDummy
        .map((kategori) => kategori.nama)
        .toSet();

    List<String> genreRapi = [];
    for (String genre in genrePilihan) {
      bool isGenreDikenal = namaGenreYangAda.contains(genre);
      bool isSudahDimasukkan = genreRapi.contains(genre);
      if (isGenreDikenal && !isSudahDimasukkan) {
        genreRapi.add(genre);
      }
    }

    _genreFavorit = genreRapi.take(batasGenreFavorit).toList();
    _susunUlangRekomendasi();
    _kabariPendengar();
  }

  List<String> _urutanKategoriSesuaiFavorit() {
    List<String> kategoriFavoritDulu = _genreFavorit
        .where((genre) => _laguPerGenre.containsKey(genre))
        .toList();

    for (String namaKategori in _laguPerGenre.keys) {
      if (!kategoriFavoritDulu.contains(namaKategori)) {
        kategoriFavoritDulu.add(namaKategori);
      }
    }
    return kategoriFavoritDulu;
  }

  int _peringkatFavorit(String namaKategori) {
    int posisi = _genreFavorit.indexOf(namaKategori);
    if (posisi == -1) return _genreFavorit.length;
    return posisi;
  }

  void _susunUlangRekomendasi() {
    Set<String> laguYangPernahDiputar = _riwayatTerakhirDiputar
        .map((riwayat) => kunciLagu(riwayat.lagu))
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

    _laguPerGenre.forEach((namaKategori, isiLagu) {
      if (isiLagu.isEmpty) return;

      int jumlahFamiliar = isiLagu
          .where((lagu) => laguYangPernahDiputar.contains(kunciLagu(lagu)))
          .length;

      hasilRacikan.add(
        RacikanUntukmu(
          namaKategori: namaKategori,
          playlist: Playlist(
            nama: 'Racikan $namaKategori',
            deskripsi: _rangkumPenyanyi(isiLagu),
            daftarLagu: isiLagu,
          ),
          warnaAksen: _cariWarnaKategori(namaKategori),
          jumlahLaguFamiliar: jumlahFamiliar,
          isGenreFavorit: _genreFavorit.contains(namaKategori),
        ),
      );
    });

    List<RacikanUntukmu> urutanAwal = List.of(hasilRacikan);
    hasilRacikan.sort((a, b) {
      int selisihPeringkat =
          _peringkatFavorit(a.namaKategori) - _peringkatFavorit(b.namaKategori);
      if (selisihPeringkat != 0) return selisihPeringkat;

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

    for (String namaKategori in _urutanKategoriSesuaiFavorit()) {
      List<Lagu> isiLagu = _laguPerGenre[namaKategori] ?? [];
      for (Lagu lagu in isiLagu) {
        String kunci = kunciLagu(lagu);
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
    _timerPenandaLambat?.cancel();
    _pemutarYangDipantau?.removeListener(_cekLaguYangSedangDiputar);
    _pemutarYangDipantau = null;
    super.dispose();
  }
}
