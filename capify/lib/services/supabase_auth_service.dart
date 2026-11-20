import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/user.dart';
import 'auth_service.dart';

class SupabaseAuthService extends AuthService {
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

  @override
  Future<User> masuk({required String email, required String password}) async {
    try {
      supabase.AuthResponse respons = await _authSupabase.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      supabase.User? penggunaSupabase = respons.user;
      if (penggunaSupabase == null) {
        throw const AuthException(
          AuthService.kodeGagalTerhubung,
          'Server tidak mengirim data akun',
        );
      }
      return ubahKeUserCapify(penggunaSupabase);
    } on supabase.AuthException catch (galat) {
      if (galat.code == 'invalid_credentials') {
        throw const AuthException(
          AuthService.kodeEmailAtauPasswordSalah,
          'Email atau password salah',
        );
      }
      if (galat.code == 'email_not_confirmed') {
        throw const AuthException(
          AuthService.kodeEmailBelumDikonfirmasi,
          'Email belum dikonfirmasi',
        );
      }
      throw AuthException(AuthService.kodeGagalTerhubung, galat.message);
    }
  }

  @override
  Future<User> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    supabase.AuthResponse respons;
    try {
      respons = await _authSupabase.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'name': rapikanNama(nama)},
      );
    } on supabase.AuthException catch (galat) {
      if (galat.code == 'user_already_exists' || galat.code == 'email_exists') {
        throw const AuthException(
          AuthService.kodeEmailSudahDipakai,
          'Email sudah dipakai akun lain',
        );
      }
      if (galat.code == 'weak_password') {
        throw const AuthException(
          AuthService.kodePasswordTerlaluLemah,
          'Password terlalu lemah',
        );
      }
      throw AuthException(AuthService.kodeGagalTerhubung, galat.message);
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
