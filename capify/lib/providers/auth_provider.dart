import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

enum KesalahanMasuk {
  emailBelumTerdaftar,
  passwordSalah,
  masihDiproses,
  gagalTerhubung,
}

enum KesalahanDaftar { emailSudahTerdaftar, masihDiproses, gagalTerhubung }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  User? _penggunaAktif;
  bool _isIngatSaya = false;
  bool _isSedangMemproses = false;

  User? get penggunaAktif => _penggunaAktif;
  bool get isSudahMasuk => _penggunaAktif != null;
  bool get isIngatSaya => _isIngatSaya;
  bool get isSedangMemproses => _isSedangMemproses;
  String get namaTampilan => _penggunaAktif?.nama ?? 'Capy Lovers';
  String get emailTampilan => _penggunaAktif?.email ?? 'Belum masuk ke akun';

  bool isEmailSudahTerdaftar(String email) {
    return _authService.isEmailTerdaftar(email);
  }

  Future<KesalahanMasuk?> masuk({
    required String email,
    required String password,
    bool isIngatSaya = false,
  }) async {
    if (_isSedangMemproses) return KesalahanMasuk.masihDiproses;

    _isSedangMemproses = true;
    notifyListeners();

    KesalahanMasuk? kesalahan;
    try {
      _penggunaAktif = await _authService.masuk(
        email: email,
        password: password,
      );
      _isIngatSaya = isIngatSaya;
    } on AuthException catch (galat) {
      if (galat.kode == AuthService.kodeEmailTidakDitemukan) {
        kesalahan = KesalahanMasuk.emailBelumTerdaftar;
      } else if (galat.kode == AuthService.kodePasswordSalah) {
        kesalahan = KesalahanMasuk.passwordSalah;
      } else {
        kesalahan = KesalahanMasuk.gagalTerhubung;
      }
    } catch (_) {
      kesalahan = KesalahanMasuk.gagalTerhubung;
    }

    _isSedangMemproses = false;
    notifyListeners();
    return kesalahan;
  }

  Future<KesalahanDaftar?> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    if (_isSedangMemproses) return KesalahanDaftar.masihDiproses;

    _isSedangMemproses = true;
    notifyListeners();

    KesalahanDaftar? kesalahan;
    try {
      await _authService.daftar(nama: nama, email: email, password: password);
    } on AuthException catch (galat) {
      kesalahan = galat.kode == AuthService.kodeEmailSudahDipakai
          ? KesalahanDaftar.emailSudahTerdaftar
          : KesalahanDaftar.gagalTerhubung;
    } catch (_) {
      kesalahan = KesalahanDaftar.gagalTerhubung;
    }

    _isSedangMemproses = false;
    notifyListeners();
    return kesalahan;
  }

  void keluar() {
    _penggunaAktif = null;
    _isIngatSaya = false;
    notifyListeners();
  }
}
