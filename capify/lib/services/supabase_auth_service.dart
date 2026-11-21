import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/user.dart';
import 'auth_service.dart';

class SupabaseAuthService extends AuthService {
  static const Duration batasTungguServer = Duration(seconds: 15);
  static const AuthException galatServerLambat = AuthException(
    AuthService.kodeServerLambat,
    'Server terlalu lama merespons',
  );

  bool _isPerluKonfirmasiEmail = false;

  supabase.GoTrueClient get _authSupabase {
    return supabase.Supabase.instance.client.auth;
  }

  @override
  bool get isPerluKonfirmasiEmail => _isPerluKonfirmasiEmail;

  @override
  bool isEmailTerdaftar(String email) => false;

  String ambilNamaDariEmail(String email) {
    String bagianSebelumAt = email.split('@').first;
    List<String> potonganKata = bagianSebelumAt
        .split(RegExp(r'[._\-+0-9]+'))
        .where((kata) => kata.isNotEmpty)
        .toList();

    if (potonganKata.isEmpty) return 'Capy Lovers';

    return potonganKata
        .map((kata) => kata[0].toUpperCase() + kata.substring(1).toLowerCase())
        .join(' ');
  }

  User ubahKeUserCapify(supabase.User penggunaSupabase) {
    Map<String, dynamic> dataTambahan = penggunaSupabase.userMetadata ?? {};
    String email = penggunaSupabase.email ?? '';
    String namaDariSupabase =
        (dataTambahan['name'] ?? dataTambahan['full_name'] ?? '')
            .toString()
            .trim();

    return User.fromJson({
      'id': penggunaSupabase.id,
      'name': namaDariSupabase.isEmpty
          ? ambilNamaDariEmail(email)
          : namaDariSupabase,
      'email': email,
      'photo_url': dataTambahan['avatar_url'] ?? '',
      'joined_at': penggunaSupabase.createdAt,
    });
  }

  AuthException terjemahkanGalatSupabase(supabase.AuthException galat) {
    if (galat is supabase.AuthRetryableFetchException) {
      bool isTidakSampaiKeServer = galat.statusCode == null;
      return AuthException(
        isTidakSampaiKeServer
            ? AuthService.kodeTidakAdaInternet
            : AuthService.kodeGagalTerhubung,
        galat.message,
      );
    }

    String kodeCapify = switch (galat.code ?? '') {
      'invalid_credentials' => AuthService.kodeEmailAtauPasswordSalah,
      'email_not_confirmed' => AuthService.kodeEmailBelumDikonfirmasi,
      'user_already_exists' ||
      'email_exists' => AuthService.kodeEmailSudahDipakai,
      'weak_password' => AuthService.kodePasswordTerlaluLemah,
      'email_address_invalid' ||
      'email_address_not_authorized' => AuthService.kodeEmailTidakBisaDipakai,
      'signup_disabled' => AuthService.kodePendaftaranDitutup,
      'over_email_send_rate_limit' => AuthService.kodeBatasEmailTercapai,
      'over_request_rate_limit' => AuthService.kodeTerlaluSering,
      _ => AuthService.kodeGagalTerhubung,
    };
    return AuthException(kodeCapify, galat.message);
  }

  @override
  Future<User> masuk({required String email, required String password}) async {
    supabase.AuthResponse respons;
    try {
      respons = await _authSupabase
          .signInWithPassword(
            email: email.trim().toLowerCase(),
            password: password,
          )
          .timeout(batasTungguServer);
    } on supabase.AuthException catch (galat) {
      throw terjemahkanGalatSupabase(galat);
    } on TimeoutException {
      throw galatServerLambat;
    }

    supabase.User? penggunaSupabase = respons.user;
    if (penggunaSupabase == null) {
      throw const AuthException(
        AuthService.kodeGagalTerhubung,
        'Server tidak mengirim data akun',
      );
    }
    return ubahKeUserCapify(penggunaSupabase);
  }

  @override
  Future<User> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    supabase.AuthResponse respons;
    try {
      respons = await _authSupabase
          .signUp(
            email: email.trim().toLowerCase(),
            password: password,
            data: {'name': rapikanNama(nama)},
          )
          .timeout(batasTungguServer);
    } on supabase.AuthException catch (galat) {
      throw terjemahkanGalatSupabase(galat);
    } on TimeoutException {
      throw galatServerLambat;
    }

    supabase.User? penggunaSupabase = respons.user;
    if (penggunaSupabase == null) {
      throw const AuthException(
        AuthService.kodeGagalTerhubung,
        'Server tidak mengirim data akun',
      );
    }

    bool isEmailPernahDipakai = penggunaSupabase.identities?.isEmpty ?? false;
    if (isEmailPernahDipakai) {
      throw const AuthException(
        AuthService.kodeEmailSudahDipakai,
        'Email sudah dipakai akun lain',
      );
    }

    _isPerluKonfirmasiEmail = respons.session == null;
    if (respons.session != null) await keluar();

    return ubahKeUserCapify(penggunaSupabase);
  }

  @override
  Future<void> keluar() async {
    try {
      await _authSupabase.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {
      return;
    }
  }
}
