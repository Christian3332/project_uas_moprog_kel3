import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/user.dart';
import 'auth_service.dart';

class SupabaseAuthService extends AuthService {
  supabase.GoTrueClient get _authSupabase {
    return supabase.Supabase.instance.client.auth;
  }

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
}
