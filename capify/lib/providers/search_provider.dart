import 'package:flutter/foundation.dart';

import '../data/lagu_dummy.dart';
import '../models/lagu.dart';

class SearchProvider extends ChangeNotifier {
  final List<Lagu> sumberLagu;
  final int batasRiwayat = 5;

  SearchProvider({this.sumberLagu = daftarLaguDummy});

  String _kataKunci = '';
  String _kataKunciTerakhirDicari = '';
  List<Lagu> _hasilPencarian = [];
  List<String> _riwayatPencarian = [];
  bool _isSedangMencari = false;
  bool _isProviderSudahDitutup = false;
  int _urutanKetikan = 0;

  String get kataKunci => _kataKunci;
  String get kataKunciBersih => _kataKunci.trim();
  bool get isKolomCariKosong => kataKunciBersih.isEmpty;
  bool get isSedangMencari => _isSedangMencari;
  bool get isHasilKosong => !_isSedangMencari && _hasilPencarian.isEmpty;
  List<Lagu> get hasilPencarian => List.unmodifiable(_hasilPencarian);
  List<String> get riwayatPencarian => List.unmodifiable(_riwayatPencarian);

  List<String> get saranPencarian {
    return sumberLagu.map((lagu) => lagu.penyanyi).toSet().toList();
  }

  void _kabariLayar() {
    if (_isProviderSudahDitutup) return;
    notifyListeners();
  }

  Future<void> cariLagu(String ketikanUser) async {
    _kataKunci = ketikanUser;
    String kataYangDicari = kataKunciBersih.toLowerCase();

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

    _hasilPencarian = sumberLagu.where((lagu) {
      bool judulCocok = lagu.judul.toLowerCase().contains(kataYangDicari);
      bool penyanyiCocok = lagu.penyanyi.toLowerCase().contains(kataYangDicari);
      return judulCocok || penyanyiCocok;
    }).toList();

    _isSedangMencari = false;
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
