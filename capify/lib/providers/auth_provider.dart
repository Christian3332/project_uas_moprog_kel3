import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/sesi_lokal_service.dart';

enum KesalahanMasuk {
  emailBelumTerdaftar,
  passwordSalah,
  emailAtauPasswordSalah,
  emailBelumDikonfirmasi,
  terlaluSeringMencoba,
  tidakAdaInternet,
  serverTerlaluLama,
  masihDiproses,
  gagalTerhubung,
}

enum KesalahanDaftar {
  emailSudahTerdaftar,
  emailTidakBisaDipakai,
  passwordTerlaluLemah,
  pendaftaranDitutup,
  batasEmailTercapai,
  terlaluSeringMencoba,
  tidakAdaInternet,
  serverTerlaluLama,
  masihDiproses,
  gagalTerhubung,
}

enum KesalahanProfil {
  belumMasuk,
  masihDiproses,
  sesiBerakhir,
  tidakAdaInternet,
  serverTerlaluLama,
  gagalTerhubung,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SesiLokalService _sesiLokal;

  AuthProvider({AuthService? authService, SesiLokalService? sesiLokal})
    : _authService = authService ?? AuthService(),
      _sesiLokal = sesiLokal ?? SesiLokalService();

  User? _penggunaAktif;
  bool _isIngatSaya = false;
  bool _isSedangMemproses = false;
  bool _isPerluKonfirmasiEmail = false;
  bool _isSedangMenyimpanProfil = false;

  User? get penggunaAktif => _penggunaAktif;
  bool get isSedangMenyimpanProfil => _isSedangMenyimpanProfil;
  bool get isSudahMasuk => _penggunaAktif != null;
  bool get isIngatSaya => _isIngatSaya;
  bool get isPerluKonfirmasiEmail => _isPerluKonfirmasiEmail;
  String get namaTampilan => _penggunaAktif?.nama ?? 'Capy Lovers';
  String get emailTampilan => _penggunaAktif?.email ?? 'Belum masuk ke akun';

  bool isEmailSudahTerdaftar(String email) {
    return _authService.isEmailTerdaftar(email);
  }

  KesalahanMasuk _ubahKeKesalahanMasuk(String kode) {
    return switch (kode) {
      AuthService.kodeEmailTidakDitemukan => KesalahanMasuk.emailBelumTerdaftar,
      AuthService.kodePasswordSalah => KesalahanMasuk.passwordSalah,
      AuthService.kodeEmailAtauPasswordSalah =>
        KesalahanMasuk.emailAtauPasswordSalah,
      AuthService.kodeEmailBelumDikonfirmasi =>
        KesalahanMasuk.emailBelumDikonfirmasi,
      AuthService.kodeTerlaluSering => KesalahanMasuk.terlaluSeringMencoba,
      AuthService.kodeTidakAdaInternet => KesalahanMasuk.tidakAdaInternet,
      AuthService.kodeServerLambat => KesalahanMasuk.serverTerlaluLama,
      _ => KesalahanMasuk.gagalTerhubung,
    };
  }

  KesalahanDaftar _ubahKeKesalahanDaftar(String kode) {
    return switch (kode) {
      AuthService.kodeEmailSudahDipakai => KesalahanDaftar.emailSudahTerdaftar,
      AuthService.kodeEmailTidakBisaDipakai =>
        KesalahanDaftar.emailTidakBisaDipakai,
      AuthService.kodePasswordTerlaluLemah =>
        KesalahanDaftar.passwordTerlaluLemah,
      AuthService.kodePendaftaranDitutup => KesalahanDaftar.pendaftaranDitutup,
      AuthService.kodeBatasEmailTercapai => KesalahanDaftar.batasEmailTercapai,
      AuthService.kodeTerlaluSering => KesalahanDaftar.terlaluSeringMencoba,
      AuthService.kodeTidakAdaInternet => KesalahanDaftar.tidakAdaInternet,
      AuthService.kodeServerLambat => KesalahanDaftar.serverTerlaluLama,
      _ => KesalahanDaftar.gagalTerhubung,
    };
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
      User penggunaBaru = await _authService.masuk(
        email: email,
        password: password,
      );
      _penggunaAktif = penggunaBaru;
      _isIngatSaya = isIngatSaya;

      if (isIngatSaya) {
        await _sesiLokal.simpanPengguna(penggunaBaru);
      } else {
        await _sesiLokal.hapusPengguna();
      }
    } on AuthException catch (galat) {
      kesalahan = _ubahKeKesalahanMasuk(galat.kode);
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
      _isPerluKonfirmasiEmail = _authService.isPerluKonfirmasiEmail;
    } on AuthException catch (galat) {
      kesalahan = _ubahKeKesalahanDaftar(galat.kode);
    } catch (_) {
      kesalahan = KesalahanDaftar.gagalTerhubung;
    }

    _isSedangMemproses = false;
    notifyListeners();
    return kesalahan;
  }

  Future<void> keluar() async {
    if (_isSedangMemproses) return;

    _isSedangMemproses = true;
    notifyListeners();

    await _authService.keluar();
    await _sesiLokal.hapusPengguna();

    _penggunaAktif = null;
    _isIngatSaya = false;
    _isSedangMemproses = false;
    notifyListeners();
  }

  KesalahanProfil _ubahKeKesalahanProfil(String kode) {
    return switch (kode) {
      AuthService.kodeSesiBerakhir => KesalahanProfil.sesiBerakhir,
      AuthService.kodeTidakAdaInternet => KesalahanProfil.tidakAdaInternet,
      AuthService.kodeServerLambat => KesalahanProfil.serverTerlaluLama,
      _ => KesalahanProfil.gagalTerhubung,
    };
  }

  Future<KesalahanProfil?> perbaruiNama(String namaBaru) async {
    User? penggunaLama = _penggunaAktif;
    if (penggunaLama == null) return KesalahanProfil.belumMasuk;
    if (_isSedangMenyimpanProfil) return KesalahanProfil.masihDiproses;

    String namaRapi = _authService.rapikanNama(namaBaru);
    if (namaRapi.isEmpty || namaRapi == penggunaLama.nama) return null;

    _penggunaAktif = penggunaLama.salinDenganNamaBaru(namaRapi);
    _isSedangMenyimpanProfil = true;
    notifyListeners();

    KesalahanProfil? kesalahan;
    try {
      User penggunaDariServer = await _authService.perbaruiNama(
        pengguna: penggunaLama,
        namaBaru: namaRapi,
      );
      if (_penggunaAktif?.id == penggunaLama.id) {
        _penggunaAktif = penggunaDariServer;
        if (_isIngatSaya) await _sesiLokal.simpanPengguna(penggunaDariServer);
      }
    } on AuthException catch (galat) {
      kesalahan = _ubahKeKesalahanProfil(galat.kode);
    } catch (_) {
      kesalahan = KesalahanProfil.gagalTerhubung;
    }

    bool isMasihAkunYangSama = _penggunaAktif?.id == penggunaLama.id;
    if (kesalahan != null && isMasihAkunYangSama) {
      _penggunaAktif = penggunaLama;
    }

    _isSedangMenyimpanProfil = false;
    notifyListeners();
    return kesalahan;
  }

  Future<void> pulihkanSesi() async {
    User? penggunaTersimpan = await _sesiLokal.ambilPengguna();

    if (penggunaTersimpan == null) {
      await _authService.keluar();
      return;
    }

    User? penggunaCocok;
    try {
      penggunaCocok = await _authService.cocokkanSesiTersimpan(
        penggunaTersimpan,
      );
    } catch (_) {
      penggunaCocok = null;
    }

    if (penggunaCocok == null) {
      await _sesiLokal.hapusPengguna();
      return;
    }

    _penggunaAktif = penggunaCocok;
    _isIngatSaya = true;
    await _sesiLokal.simpanPengguna(penggunaCocok);
    notifyListeners();
  }
}
