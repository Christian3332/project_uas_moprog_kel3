import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/album_dummy.dart';
import '../data/lagu_dummy.dart';
import '../data/lagu_per_kategori_dummy.dart';
import '../models/album.dart';
import '../models/hasil_pencarian.dart';
import '../models/lagu.dart';
import '../services/search_service.dart';
import '../utils/saran_ejaan.dart';

List<Lagu> kumpulkanSemuaLaguDummy() {
  List<Lagu> semuaLagu = [];
  Set<String> laguYangSudahMasuk = {};

  List<Lagu> laguMentah = [
    ...daftarLaguDummy,
    for (List<Lagu> laguSatuKategori in laguPerKategoriDummy.values)
      ...laguSatuKategori,
  ];

  for (Lagu lagu in laguMentah) {
    String tandaLagu = '${lagu.judul}|${lagu.penyanyi}'.toLowerCase();
    if (laguYangSudahMasuk.add(tandaLagu)) {
      semuaLagu.add(lagu);
    }
  }
  return semuaLagu;
}

class SearchProvider extends ChangeNotifier {
  static const String filterSemua = 'Semua';
  static const String filterJudul = 'Judul';
  static const String filterPenyanyi = 'Penyanyi';
  static const List<String> pilihanFilter = [
    filterSemua,
    filterJudul,
    filterPenyanyi,
  ];

  final SearchService searchService;
  final Duration jedaSetelahMengetik;
  final List<String> saranPencarian;
  final int batasRiwayat = 5;
  final int batasHasilDariServer = 20;
  final int minimalHurufUntukCari = 2;
  final int batasIsiCache = 20;

  final List<String> kamusSaranEjaan;

  SearchProvider({
    SearchService? searchService,
    this.jedaSetelahMengetik = const Duration(milliseconds: 450),
    List<String>? saranPencarian,
    List<String>? kamusSaranEjaan,
  }) : searchService = searchService ?? SearchService(),
       saranPencarian =
           saranPencarian ??
           kumpulkanSemuaLaguDummy()
               .map((lagu) => lagu.penyanyi)
               .toSet()
               .take(8)
               .toList(),
       kamusSaranEjaan = kamusSaranEjaan ?? susunKamusSaranDummy();

  static List<String> susunKamusSaranDummy() {
    return {
      for (Lagu lagu in kumpulkanSemuaLaguDummy()) ...[
        lagu.judul,
        lagu.penyanyi,
      ],
      for (Album album in daftarAlbumTersimpanDummy) album.judul,
    }.toList();
  }

  String? _saranEjaan;
  String _kataKunci = '';
  String _kataKunciHasilTampil = '';
  String _filterAktif = filterSemua;
  HasilPencarian? _hasilDariServer;
  List<Lagu> _laguTampil = [];
  List<Album> _albumTampil = [];
  List<String> _riwayatPencarian = [];
  final Map<String, HasilPencarian> _cacheHasil = {};
  Timer? _timerTungguKetikan;
  String? _pesanError;
  bool _isSedangMencari = false;
  bool _isProviderSudahDitutup = false;
  int _urutanPermintaan = 0;
  int _jumlahPanggilanApi = 0;

  String get kataKunci => _kataKunci;
  String get kataKunciBersih => _kataKunci.trim();
  String get filterAktif => _filterAktif;
  bool get isFilterSemua => _filterAktif == filterSemua;
  bool get isKolomCariKosong => kataKunciBersih.isEmpty;
  bool get isSedangMencari => _isSedangMencari;
  String? get pesanError => _pesanError;
  bool get isAdaError => _pesanError != null;
  bool get isHasilDariCadangan => _hasilDariServer?.isDariCadangan ?? false;
  int get jumlahPanggilanApi => _jumlahPanggilanApi;
  List<Lagu> get hasilPencarian => List.unmodifiable(_laguTampil);
  List<Album> get albumDitemukan => List.unmodifiable(_albumTampil);
  List<String> get riwayatPencarian => List.unmodifiable(_riwayatPencarian);

  bool get isKataKunciKependekan {
    if (isKolomCariKosong) return false;
    return potonganKataKunci.join(' ').length < minimalHurufUntukCari;
  }

  bool get isHasilKosong {
    if (isKolomCariKosong || isKataKunciKependekan) return false;
    if (_isSedangMencari || isAdaError) return false;
    return _laguTampil.isEmpty && _albumTampil.isEmpty;
  }

  String? get saranEjaan => isHasilKosong ? _saranEjaan : null;

  int get jumlahHasilTanpaFilter {
    HasilPencarian? hasil = _hasilDariServer;
    if (hasil == null) return 0;
    return hasil.jumlahSemuaHasil;
  }

  bool get isHasilTersembunyiOlehFilter {
    return isHasilKosong && !isFilterSemua && jumlahHasilTanpaFilter > 0;
  }

  String? get kataTunggalUntukDicoba {
    List<String> semuaKata = potonganKataKunci
        .where((kata) => kata.length >= minimalHurufUntukCari)
        .toList();
    if (potonganKataKunci.length < 2 || semuaKata.isEmpty) return null;

    List<String> kataYangDikenal = semuaKata.where((kata) {
      return kamusSaranEjaan.any((frasa) => frasa.toLowerCase().contains(kata));
    }).toList();
    List<String> kandidat = kataYangDikenal.isEmpty
        ? semuaKata
        : kataYangDikenal;

    return kandidat.reduce(
      (kataJuara, kata) => kata.length > kataJuara.length ? kata : kataJuara,
    );
  }

  List<String> get potonganKataKunci {
    return SearchService.pecahKataKunci(kataKunciBersih);
  }

  List<String> get kataSorotanJudul {
    return _filterAktif == filterPenyanyi ? [] : potonganKataKunci;
  }

  List<String> get kataSorotanPenyanyi {
    return _filterAktif == filterJudul ? [] : potonganKataKunci;
  }

  void _kabariLayar() {
    if (_isProviderSudahDitutup) return;
    notifyListeners();
  }

  bool _isLolosFilter(String judul, String penyanyi) {
    if (_filterAktif == filterSemua) return true;

    String teksYangDiperiksa = _filterAktif == filterJudul
        ? judul.toLowerCase()
        : penyanyi.toLowerCase();
    return potonganKataKunci.every((kata) => teksYangDiperiksa.contains(kata));
  }

  void _jalankanFilter() {
    HasilPencarian? hasil = _hasilDariServer;
    if (hasil == null) {
      _laguTampil = [];
      _albumTampil = [];
      return;
    }

    _laguTampil = hasil.daftarTrack
        .where((track) => _isLolosFilter(track.judul, track.penyanyi))
        .map((track) => track.keLagu())
        .toList();
    _albumTampil = hasil.daftarAlbum
        .where((album) => _isLolosFilter(album.judul, album.penyanyi))
        .toList();
  }

  void _pasangHasil(String kataYangDicari, HasilPencarian? hasil) {
    _hasilDariServer = hasil;
    _kataKunciHasilTampil = hasil == null ? '' : kataYangDicari;
    _saranEjaan = hasil != null && hasil.isKosong
        ? cariSaranEjaan(kataYangDicari, kamusSaranEjaan)
        : null;
    _jalankanFilter();
  }

  void _simpanKeCache(String kataYangDicari, HasilPencarian hasil) {
    if (hasil.isDariCadangan) return;

    _cacheHasil.remove(kataYangDicari);
    _cacheHasil[kataYangDicari] = hasil;
    if (_cacheHasil.length > batasIsiCache) {
      _cacheHasil.remove(_cacheHasil.keys.first);
    }
  }

  String? _siapkanPencarian(String ketikanUser) {
    _kataKunci = ketikanUser;
    _timerTungguKetikan?.cancel();
    String kataYangDicari = potonganKataKunci.join(' ');

    bool isHasilnyaSudahTampil =
        kataYangDicari == _kataKunciHasilTampil && !isAdaError;
    bool isTidakPerluKeServer = kataYangDicari.isEmpty || isKataKunciKependekan;
    HasilPencarian? hasilDariCache = _cacheHasil[kataYangDicari];

    if (isHasilnyaSudahTampil ||
        isTidakPerluKeServer ||
        hasilDariCache != null) {
      _urutanPermintaan++;
      _isSedangMencari = false;
      _pesanError = null;
      if (isTidakPerluKeServer) {
        _pasangHasil('', null);
        if (kataYangDicari.isEmpty) _filterAktif = filterSemua;
      } else if (!isHasilnyaSudahTampil) {
        _simpanKeCache(kataYangDicari, hasilDariCache!);
        _pasangHasil(kataYangDicari, hasilDariCache);
      }
      _kabariLayar();
      return null;
    }

    return kataYangDicari;
  }

  void ketikKataKunci(String ketikanUser) {
    String? kataYangDicari = _siapkanPencarian(ketikanUser);
    if (kataYangDicari == null) return;

    _urutanPermintaan++;
    _isSedangMencari = true;
    _pesanError = null;
    _kabariLayar();

    _timerTungguKetikan = Timer(
      jedaSetelahMengetik,
      () => _ambilDariServer(kataYangDicari),
    );
  }

  Future<void> cariSekarang(String kataKunciBaru) async {
    String? kataYangDicari = _siapkanPencarian(kataKunciBaru);
    if (kataYangDicari == null) return;

    await _ambilDariServer(kataYangDicari);
  }

  Future<void> cobaLagi() async {
    _timerTungguKetikan?.cancel();
    String kataYangDicari = potonganKataKunci.join(' ');
    if (kataYangDicari.isEmpty || isKataKunciKependekan) return;

    await _ambilDariServer(kataYangDicari);
  }

  Future<void> _ambilDariServer(String kataYangDicari) async {
    if (_isProviderSudahDitutup) return;

    _urutanPermintaan++;
    int permintaanIniKe = _urutanPermintaan;
    _isSedangMencari = true;
    _pesanError = null;
    _kabariLayar();

    _jumlahPanggilanApi++;
    HasilPencarian? hasilBaru;
    String? pesanGagal;
    try {
      hasilBaru = await searchService.cari(
        kataYangDicari,
        batasPerJenis: batasHasilDariServer,
      );
    } on SearchException catch (masalah) {
      pesanGagal = masalah.pesan;
    } catch (_) {
      pesanGagal = 'Pencarian gagal, periksa koneksi internetmu lalu coba lagi';
    }

    if (_isProviderSudahDitutup || permintaanIniKe != _urutanPermintaan) {
      return;
    }

    if (hasilBaru != null) {
      _simpanKeCache(kataYangDicari, hasilBaru);
    }
    _pasangHasil(kataYangDicari, hasilBaru);
    _pesanError = pesanGagal;
    _isSedangMencari = false;
    _kabariLayar();
  }

  void gantiFilter(String filterBaru) {
    if (filterBaru == _filterAktif) return;
    if (!pilihanFilter.contains(filterBaru)) return;

    _filterAktif = filterBaru;
    _jalankanFilter();
    _kabariLayar();
  }

  void simpanKeRiwayat(String kataKunciBaru) {
    String kataRapi = kataKunciBaru.trim();
    if (kataRapi.isEmpty) return;

    _riwayatPencarian.removeWhere(
      (kataLama) => kataLama.toLowerCase() == kataRapi.toLowerCase(),
    );
    _riwayatPencarian.insert(0, kataRapi);

    if (_riwayatPencarian.length > batasRiwayat) {
      _riwayatPencarian = _riwayatPencarian.sublist(0, batasRiwayat);
    }
    _kabariLayar();
  }

  void hapusSatuRiwayat(String kataLama) {
    if (!_riwayatPencarian.remove(kataLama)) return;
    _kabariLayar();
  }

  void hapusSemuaRiwayat() {
    if (_riwayatPencarian.isEmpty) return;
    _riwayatPencarian = [];
    _kabariLayar();
  }

  void kosongkanPencarian() {
    _siapkanPencarian('');
  }

  void bersihkanSemuaPencarian() {
    _riwayatPencarian = [];
    _cacheHasil.clear();
    _siapkanPencarian('');
  }

  @override
  void dispose() {
    _isProviderSudahDitutup = true;
    _timerTungguKetikan?.cancel();
    super.dispose();
  }
}
