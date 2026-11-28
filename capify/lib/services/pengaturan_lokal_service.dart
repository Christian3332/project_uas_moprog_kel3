import 'package:shared_preferences/shared_preferences.dart';

class PengaturanLokalService {
  static const String kunciPutarOtomatis = 'capify_putar_otomatis';
  static const String kunciNotifikasi = 'capify_notifikasi';
  static const String kunciHematData = 'capify_hemat_data';
  static const String kunciKualitasStreaming = 'capify_kualitas_streaming';

  const PengaturanLokalService();

  Future<bool> ambilSaklar(String kunci, {required bool nilaiAwal}) async {
    try {
      SharedPreferences penyimpanan = await SharedPreferences.getInstance();
      return penyimpanan.getBool(kunci) ?? nilaiAwal;
    } catch (_) {
      return nilaiAwal;
    }
  }

  Future<void> simpanSaklar(String kunci, bool nilai) async {
    try {
      SharedPreferences penyimpanan = await SharedPreferences.getInstance();
      await penyimpanan.setBool(kunci, nilai);
    } catch (_) {
      return;
    }
  }

  Future<String> ambilKualitasStreaming({required String nilaiAwal}) async {
    try {
      SharedPreferences penyimpanan = await SharedPreferences.getInstance();
      return penyimpanan.getString(kunciKualitasStreaming) ?? nilaiAwal;
    } catch (_) {
      return nilaiAwal;
    }
  }

  Future<void> simpanKualitasStreaming(String kualitas) async {
    try {
      SharedPreferences penyimpanan = await SharedPreferences.getInstance();
      await penyimpanan.setString(kunciKualitasStreaming, kualitas);
    } catch (_) {
      return;
    }
  }
}
