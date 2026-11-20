import 'package:flutter/foundation.dart';

import '../data/lagu_dummy.dart';
import '../data/lagu_per_kategori_dummy.dart';
import '../models/album.dart';
import '../models/hasil_pencarian.dart';
import '../models/lagu.dart';
import '../services/search_service.dart';

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

  SearchProvider({
    SearchService? searchService,
    this.jedaSetelahMengetik = const Duration(milliseconds: 350),
    List<String>? saranPencarian,
  }) : searchService = searchService ?? SearchService(),
       saranPencarian =
           saranPencarian ??
           kumpulkanSemuaLaguDummy()
               .map((lagu) => lagu.penyanyi)
               .toSet()
               .take(8)
               .toList();

  String _kataKunci = '';
  String _kataKunciTerakhirDicari = '';
  String _filterAktif = filterSemua;
  HasilPencarian? _hasilDariServer;
  List<Lagu> _laguTampil = [];
  List<Album> _albumTampil = [];
  List<String> _riwayatPencarian = [];
  String? _pesanError;
  bool _isSedangMencari = false;
  bool _isProviderSudahDitutup = false;
  int _urutanKetikan = 0;

  String get kataKunci => _kataKunci;
  String get kataKunciBersih => _kataKunci.trim();
  String get filterAktif => _filterAktif;
  bool get isFilterSemua => _filterAktif == filterSemua;
  bool get isKolomCariKosong => kataKunciBersih.isEmpty;
  bool get isSedangMencari => _isSedangMencari;
  String? get pesanError => _pesanError;
  bool get isAdaError => _pesanError != null;
  bool get isHasilDariCadangan => _hasilDariServer?.isDariCadangan ?? false;
  List<Lagu> get hasilPencarian => List.unmodifiable(_laguTampil);
  List<Album> get albumDitemukan => List.unmodifiable(_albumTampil);
  List<String> get riwayatPencarian => List.unmodifiable(_riwayatPencarian);

  bool get isHasilKosong {
    if (_isSedangMencari || isAdaError) return false;
    return _laguTampil.isEmpty && _albumTampil.isEmpty;
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

  bool _isKetikanSudahBasi(int ketikanIniKe) {
    return _isProviderSudahDitutup || ketikanIniKe != _urutanKetikan;
  }

  Future<void> cariLagu(String ketikanUser) async {
    _kataKunci = ketikanUser;
    String kataYangDicari = potonganKataKunci.join(' ');

    if (kataYangDicari == _kataKunciTerakhirDicari) {
      _kabariLayar();
      return;
    }

    _kataKunciTerakhirDicari = kataYangDicari;
    _urutanKetikan++;
    int ketikanIniKe = _urutanKetikan;
    _pesanError = null;

    if (kataYangDicari.isEmpty) {
      _hasilDariServer = null;
      _jalankanFilter();
      _isSedangMencari = false;
      _kabariLayar();
      return;
    }

    _isSedangMencari = true;
    _kabariLayar();

    await Future.delayed(jedaSetelahMengetik);
    if (_isKetikanSudahBasi(ketikanIniKe)) return;

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

    if (_isKetikanSudahBasi(ketikanIniKe)) return;

    _hasilDariServer = hasilBaru;
    _pesanError = pesanGagal;
    _jalankanFilter();
    _isSedangMencari = false;
    _kabariLayar();
  }

  Future<void> cobaLagi() {
    _kataKunciTerakhirDicari = '';
    return cariLagu(_kataKunci);
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
    cariLagu('');
  }

  @override
  void dispose() {
    _isProviderSudahDitutup = true;
    super.dispose();
  }
}
