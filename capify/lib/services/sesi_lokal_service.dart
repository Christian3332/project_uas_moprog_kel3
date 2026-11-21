import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class SesiLokalService {
  static const String kunciPenggunaTersimpan = 'capify_pengguna_tersimpan';

  Future<void> simpanPengguna(User pengguna) async {
    try {
      SharedPreferences penyimpanan = await SharedPreferences.getInstance();
      await penyimpanan.setString(
        kunciPenggunaTersimpan,
        jsonEncode(pengguna.toJson()),
      );
    } catch (_) {
      return;
    }
  }

  Future<User?> ambilPengguna() async {
    try {
      SharedPreferences penyimpanan = await SharedPreferences.getInstance();
      String? teksJson = penyimpanan.getString(kunciPenggunaTersimpan);
      if (teksJson == null || teksJson.trim().isEmpty) return null;

      dynamic hasilDecode = jsonDecode(teksJson);
      if (hasilDecode is! Map<String, dynamic>) {
        await hapusPengguna();
        return null;
      }

      User pengguna = User.fromJson(hasilDecode);
      if (pengguna.email.isEmpty) {
        await hapusPengguna();
        return null;
      }
      return pengguna;
    } catch (_) {
      await hapusPengguna();
      return null;
    }
  }

  Future<void> hapusPengguna() async {
    try {
      SharedPreferences penyimpanan = await SharedPreferences.getInstance();
      await penyimpanan.remove(kunciPenggunaTersimpan);
    } catch (_) {
      return;
    }
  }
}
