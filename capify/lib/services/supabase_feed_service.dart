import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/feed_beranda.dart';
import 'feed_service.dart';

class SupabaseFeedService extends FeedService {
  static const String namaTabelLagu = 'tracks';
  static const String namaTabelRiwayat = 'recently_played';
  static const int batasRiwayatDiambil = 30;

  final Duration batasWaktuTunggu;

  const SupabaseFeedService({
    this.batasWaktuTunggu = const Duration(seconds: 10),
    super.lamaResponServer = Duration.zero,
  });

  @override
  Future<FeedBeranda> ambilFeedBeranda() async {
    try {
      SupabaseClient klienSupabase = Supabase.instance.client;

      List<Map<String, dynamic>> barisLagu = await klienSupabase
          .from(namaTabelLagu)
          .select('id, title, artist, cover_url, audio_url, duration_ms, genre')
          .order('title')
          .timeout(batasWaktuTunggu);

      List<Map<String, dynamic>> barisRiwayat = await _ambilRiwayatPengguna(
        klienSupabase,
      );

      FeedBeranda feedDariServer = FeedBeranda.fromJson(
        susunJsonFeed(barisLagu, barisRiwayat, DateTime.now()),
      );

      if (feedDariServer.jumlahLaguDiKatalog == 0) {
        throw Exception('Katalog lagu di server masih kosong');
      }
      return feedDariServer;
    } catch (_) {
      FeedBeranda feedCadangan = await super.ambilFeedBeranda();
      return feedCadangan.tandaiSebagaiCadangan();
    }
  }

  Future<List<Map<String, dynamic>>> _ambilRiwayatPengguna(
    SupabaseClient klienSupabase,
  ) async {
    User? penggunaAktif = klienSupabase.auth.currentUser;
    if (penggunaAktif == null) return [];

    try {
      return await klienSupabase
          .from(namaTabelRiwayat)
          .select('track_id, played_at')
          .eq('user_id', penggunaAktif.id)
          .order('played_at', ascending: false)
          .limit(batasRiwayatDiambil)
          .timeout(batasWaktuTunggu);
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> susunJsonFeed(
    List<Map<String, dynamic>> barisLagu,
    List<Map<String, dynamic>> barisRiwayat,
    DateTime waktuSekarang,
  ) {
    List<Map<String, dynamic>> riwayatSiapPakai = [];
    Set<String> laguYangSudahMasukRiwayat = {};

    for (Map<String, dynamic> baris in barisRiwayat) {
      String idLagu = baris['track_id']?.toString() ?? '';
      DateTime? waktuDiputar = DateTime.tryParse('${baris['played_at']}');

      if (idLagu.isEmpty || waktuDiputar == null) continue;
      if (laguYangSudahMasukRiwayat.contains(idLagu)) continue;

      int menitYangLalu = waktuSekarang.difference(waktuDiputar).inMinutes;
      riwayatSiapPakai.add({
        'track_id': idLagu,
        'played_minutes_ago': menitYangLalu < 0 ? 0 : menitYangLalu,
      });
      laguYangSudahMasukRiwayat.add(idLagu);
    }

    return {'tracks': barisLagu, 'recently_played': riwayatSiapPakai};
  }
}
