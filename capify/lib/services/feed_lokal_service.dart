import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed_beranda.dart';

class FeedLokalService {
  static const String awalanKunci = 'capify_feed_terakhir_';

  final Duration batasTungguPenyimpanan;

  const FeedLokalService({
    this.batasTungguPenyimpanan = const Duration(seconds: 3),
  });

  Future<SharedPreferences> bukaPenyimpanan() {
    return SharedPreferences.getInstance().timeout(batasTungguPenyimpanan);
  }

  String kunciUntuk(String idPengguna) {
    String idRapi = idPengguna.trim();
    return '$awalanKunci${idRapi.isEmpty ? 'tamu' : idRapi}';
  }

  Future<void> simpanFeed(
    String idPengguna,
    FeedBeranda feed, {
    DateTime? waktuSimpan,
  }) async {
    if (feed.jumlahLaguDiKatalog == 0) return;

    try {
      SharedPreferences penyimpanan = await bukaPenyimpanan();
      await penyimpanan.setString(
        kunciUntuk(idPengguna),
        jsonEncode({
          'saved_at': (waktuSimpan ?? DateTime.now()).toIso8601String(),
          'feed': feed.toJson(),
        }),
      );
    } catch (_) {
      return;
    }
  }

  Future<FeedBeranda?> ambilFeed(
    String idPengguna, {
    DateTime? waktuSekarang,
  }) async {
    try {
      SharedPreferences penyimpanan = await bukaPenyimpanan();
      String? teksJson = penyimpanan.getString(kunciUntuk(idPengguna));
      if (teksJson == null || teksJson.trim().isEmpty) return null;

      dynamic hasilDecode = jsonDecode(teksJson);
      if (hasilDecode is! Map<String, dynamic> ||
          hasilDecode['feed'] is! Map<String, dynamic>) {
        await hapusFeed(idPengguna);
        return null;
      }

      FeedBeranda feedTersimpan = FeedBeranda.fromJson(hasilDecode['feed']);
      if (feedTersimpan.jumlahLaguDiKatalog == 0) {
        await hapusFeed(idPengguna);
        return null;
      }

      DateTime? waktuDisimpan = DateTime.tryParse('${hasilDecode['saved_at']}');
      Duration waktuYangSudahLewat = waktuDisimpan == null
          ? Duration.zero
          : (waktuSekarang ?? DateTime.now()).difference(waktuDisimpan);

      return feedTersimpan
          .geserWaktuRiwayat(waktuYangSudahLewat)
          .tandaiAsal(AsalFeed.simpananTerakhir, waktuDisimpan: waktuDisimpan);
    } on TimeoutException {
      return null;
    } catch (_) {
      await hapusFeed(idPengguna);
      return null;
    }
  }

  Future<void> hapusFeed(String idPengguna) async {
    try {
      SharedPreferences penyimpanan = await bukaPenyimpanan();
      await penyimpanan.remove(kunciUntuk(idPengguna));
    } catch (_) {
      return;
    }
  }
}
