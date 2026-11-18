import 'package:flutter/foundation.dart';

import '../models/akun_pengguna.dart';

enum KesalahanMasuk { emailBelumTerdaftar, passwordSalah, masihDiproses }

class AuthProvider extends ChangeNotifier {
  final Map<String, AkunPengguna> _akunTerdaftar = {
    'capy@capify.id': const AkunPengguna(
      nama: 'Capy Lovers',
      email: 'capy@capify.id',
      password: 'capy123',
    ),
  };

  AkunPengguna? _akunAktif;
  bool _isIngatSaya = false;
  bool _isSedangMemproses = false;

  AkunPengguna? get akunAktif => _akunAktif;
  bool get isSudahMasuk => _akunAktif != null;
  bool get isIngatSaya => _isIngatSaya;
  bool get isSedangMemproses => _isSedangMemproses;
  String get namaTampilan => _akunAktif?.nama ?? 'Capy Lovers';
  String get emailTampilan => _akunAktif?.email ?? 'Belum masuk ke akun';

  String _rapikanEmail(String email) => email.trim().toLowerCase();

  String _rapikanNama(String nama) {
    return nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((kata) => kata.isNotEmpty)
        .map((kata) => kata[0].toUpperCase() + kata.substring(1).toLowerCase())
        .join(' ');
  }

  Future<KesalahanMasuk?> masuk({
    required String email,
    required String password,
    bool isIngatSaya = false,
  }) async {
    if (_isSedangMemproses) return KesalahanMasuk.masihDiproses;

    _isSedangMemproses = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    AkunPengguna? akunDitemukan = _akunTerdaftar[_rapikanEmail(email)];
    KesalahanMasuk? kesalahan;

    if (akunDitemukan == null) {
      kesalahan = KesalahanMasuk.emailBelumTerdaftar;
    } else if (akunDitemukan.password != password) {
      kesalahan = KesalahanMasuk.passwordSalah;
    } else {
      _akunAktif = akunDitemukan;
      _isIngatSaya = isIngatSaya;
    }

    _isSedangMemproses = false;
    notifyListeners();
    return kesalahan;
  }

  Future<String?> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    if (_isSedangMemproses) return 'Masih diproses, tunggu sebentar ya';

    _isSedangMemproses = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    String emailRapi = _rapikanEmail(email);
    String? pesanGagal;

    if (_akunTerdaftar.containsKey(emailRapi)) {
      pesanGagal = 'Email ini sudah terdaftar, silakan masuk';
    } else {
      _akunTerdaftar[emailRapi] = AkunPengguna(
        nama: _rapikanNama(nama),
        email: emailRapi,
        password: password,
      );
    }

    _isSedangMemproses = false;
    notifyListeners();
    return pesanGagal;
  }

  void keluar() {
    _akunAktif = null;
    _isIngatSaya = false;
    notifyListeners();
  }
}
