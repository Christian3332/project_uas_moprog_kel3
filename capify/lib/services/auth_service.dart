import '../models/user.dart';

class AuthException implements Exception {
  final String kode;
  final String pesan;

  const AuthException(this.kode, this.pesan);

  @override
  String toString() => pesan;
}

class AuthService {
  static const String kodeEmailTidakDitemukan = 'EMAIL_NOT_FOUND';
  static const String kodePasswordSalah = 'WRONG_PASSWORD';
  static const String kodeEmailSudahDipakai = 'EMAIL_ALREADY_USED';
  static const String kodeEmailAtauPasswordSalah = 'INVALID_CREDENTIALS';
  static const String kodeEmailBelumDikonfirmasi = 'EMAIL_NOT_CONFIRMED';
  static const String kodeGagalTerhubung = 'NETWORK_ERROR';
  static const String kodePasswordTerlaluLemah = 'WEAK_PASSWORD';
  static const String kodeTidakAdaInternet = 'NO_INTERNET';
  static const String kodeServerLambat = 'TIMEOUT';
  static const String kodeTerlaluSering = 'TOO_MANY_REQUESTS';
  static const String kodeBatasEmailTercapai = 'EMAIL_RATE_LIMIT';
  static const String kodeEmailTidakBisaDipakai = 'EMAIL_NOT_ALLOWED';
  static const String kodePendaftaranDitutup = 'SIGNUP_DISABLED';
  static const String kodeSesiBerakhir = 'SESSION_EXPIRED';

  final Duration lamaMenunggu;

  AuthService({this.lamaMenunggu = const Duration(seconds: 2)});

  final Map<String, Map<String, dynamic>> _tabelAkun = {
    'capy@capify.id': {
      'id': 'usr-001',
      'name': 'Capy Lovers',
      'email': 'capy@capify.id',
      'password': 'capy123',
      'photo_url': '',
      'joined_at': '2026-11-01T08:00:00.000',
    },
  };
  int _nomorIdBerikutnya = 2;

  String _rapikanEmail(String email) => email.trim().toLowerCase();

  String rapikanNama(String nama) {
    return nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((kata) => kata.isNotEmpty)
        .map((kata) => kata[0].toUpperCase() + kata.substring(1).toLowerCase())
        .join(' ');
  }

  Map<String, dynamic> _buangPassword(Map<String, dynamic> barisAkun) {
    return Map.of(barisAkun)..remove('password');
  }

  bool get isPerluKonfirmasiEmail => false;

  Future<void> keluar() async {
    await Future.delayed(lamaMenunggu ~/ 4);
  }

  Future<User?> cocokkanSesiTersimpan(User penggunaTersimpan) async {
    return penggunaTersimpan;
  }

  Future<User> perbaruiNama({
    required User pengguna,
    required String namaBaru,
  }) async {
    await Future.delayed(lamaMenunggu ~/ 2);

    String namaRapi = rapikanNama(namaBaru);
    Map<String, dynamic>? barisAkun = _tabelAkun[_rapikanEmail(pengguna.email)];
    if (barisAkun != null) barisAkun['name'] = namaRapi;

    return pengguna.salinDenganNamaBaru(namaRapi);
  }

  bool isEmailTerdaftar(String email) {
    return _tabelAkun.containsKey(_rapikanEmail(email));
  }

  Future<User> masuk({required String email, required String password}) async {
    await Future.delayed(lamaMenunggu);

    Map<String, dynamic>? barisAkun = _tabelAkun[_rapikanEmail(email)];
    if (barisAkun == null) {
      throw const AuthException(
        kodeEmailTidakDitemukan,
        'Email belum terdaftar',
      );
    }
    if (barisAkun['password'] != password) {
      throw const AuthException(kodePasswordSalah, 'Password salah');
    }

    return User.fromJson(_buangPassword(barisAkun));
  }

  Future<User> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    await Future.delayed(lamaMenunggu);

    String emailRapi = _rapikanEmail(email);
    if (_tabelAkun.containsKey(emailRapi)) {
      throw const AuthException(
        kodeEmailSudahDipakai,
        'Email sudah dipakai akun lain',
      );
    }

    Map<String, dynamic> barisAkunBaru = {
      'id': 'usr-${_nomorIdBerikutnya.toString().padLeft(3, '0')}',
      'name': rapikanNama(nama),
      'email': emailRapi,
      'password': password,
      'photo_url': '',
      'joined_at': DateTime.now().toIso8601String(),
    };
    _nomorIdBerikutnya++;
    _tabelAkun[emailRapi] = barisAkunBaru;

    return User.fromJson(_buangPassword(barisAkunBaru));
  }
}
