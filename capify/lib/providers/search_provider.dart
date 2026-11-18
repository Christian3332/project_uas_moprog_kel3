import 'package:flutter/foundation.dart';

import '../data/lagu_dummy.dart';
import '../data/lagu_per_kategori_dummy.dart';
import '../models/lagu.dart';

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

  final List<Lagu> sumberLagu;
  final int batasRiwayat = 5;
  final int batasSaran = 8;

  SearchProvider({List<Lagu>? sumberLagu})
    : sumberLagu = sumberLagu ?? kumpulkanSemuaLaguDummy();

  String _kataKunci = '';
  String _kataKunciTerakhirDicari = '';
  String _filterAktif = filterSemua;
  List<Lagu> _hasilPencarian = [];
  List<String> _riwayatPencarian = [];
  bool _isSedangMencari = false;
  bool _isProviderSudahDitutup = false;
  int _urutanKetikan = 0;

  String get kataKunci => _kataKunci;
  String get kataKunciBersih => _kataKunci.trim();
  String get filterAktif => _filterAktif;
  bool get isFilterSemua => _filterAktif == filterSemua;
  bool get isKolomCariKosong => kataKunciBersih.isEmpty;
  bool get isSedangMencari => _isSedangMencari;
  bool get isHasilKosong => !_isSedangMencari && _hasilPencarian.isEmpty;
  List<Lagu> get hasilPencarian => List.unmodifiable(_hasilPencarian);
  List<String> get riwayatPencarian => List.unmodifiable(_riwayatPencarian);

  List<String> get potonganKataKunci {
    return kataKunciBersih
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((kata) => kata.isNotEmpty)
        .toList();
  }

  List<String> get kataSorotanJudul {
    return _filterAktif == filterPenyanyi ? [] : potonganKataKunci;
  }

  List<String> get kataSorotanPenyanyi {
    return _filterAktif == filterJudul ? [] : potonganKataKunci;
  }

  List<String> get saranPencarian {
    return sumberLagu
        .map((lagu) => lagu.penyanyi)
        .toSet()
        .take(batasSaran)
        .toList();
  }

  void _kabariLayar() {
    if (_isProviderSudahDitutup) return;
    notifyListeners();
  }

  String _teksYangDiperiksa(Lagu lagu) {
    if (_filterAktif == filterJudul) return lagu.judul.toLowerCase();
    if (_filterAktif == filterPenyanyi) return lagu.penyanyi.toLowerCase();
    return '${lagu.judul} ${lagu.penyanyi}'.toLowerCase();
  }

  bool _isLaguCocok(Lagu lagu, List<String> semuaPotonganKata) {
    String teksLagu = _teksYangDiperiksa(lagu);
    return semuaPotonganKata.every((kata) => teksLagu.contains(kata));
  }

  void _jalankanFilter() {
    List<String> semuaPotonganKata = potonganKataKunci;
    String kataUtuh = semuaPotonganKata.join(' ');

    List<Lagu> judulDiawaliKataKunci = [];
    List<Lagu> judulMengandungKataKunci = [];
    List<Lagu> cocokLewatPenyanyi = [];

    for (Lagu lagu in sumberLagu) {
      if (!_isLaguCocok(lagu, semuaPotonganKata)) continue;

      String judulKecil = lagu.judul.toLowerCase();
      if (judulKecil.startsWith(kataUtuh)) {
        judulDiawaliKataKunci.add(lagu);
      } else if (judulKecil.contains(kataUtuh)) {
        judulMengandungKataKunci.add(lagu);
      } else {
        cocokLewatPenyanyi.add(lagu);
      }
    }

    _hasilPencarian = [
      ...judulDiawaliKataKunci,
      ...judulMengandungKataKunci,
      ...cocokLewatPenyanyi,
    ];
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

    if (kataYangDicari.isEmpty) {
      _hasilPencarian = [];
      _isSedangMencari = false;
      _kabariLayar();
      return;
    }

    _isSedangMencari = true;
    _kabariLayar();

    await Future.delayed(const Duration(milliseconds: 500));

    if (_isProviderSudahDitutup || ketikanIniKe != _urutanKetikan) return;

    _jalankanFilter();
    _isSedangMencari = false;
    _kabariLayar();
  }

  void gantiFilter(String filterBaru) {
    if (filterBaru == _filterAktif) return;
    if (!pilihanFilter.contains(filterBaru)) return;

    _filterAktif = filterBaru;
    if (!_isSedangMencari && !isKolomCariKosong) {
      _jalankanFilter();
    }
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
