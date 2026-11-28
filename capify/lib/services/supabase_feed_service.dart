import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/feed_beranda.dart';
import '../models/lagu.dart';
import 'feed_lokal_service.dart';
import 'feed_service.dart';

class SupabaseFeedService extends FeedService {
  static const String namaTabelLagu = 'tracks';
  static const String namaTabelRiwayat = 'recently_played';
  static const int batasRiwayatDiambil = 30;

  static const List<String> cirinyaTidakAdaInternet = [
    'socketexception',
    'failed host lookup',
    'network is unreachable',
    'connection refused',
    'connection reset',
    'connection closed',
    'connection failed',
    'clientexception',
    'xmlhttprequest error',
    'failed to fetch',
    'no address associated',
  ];

  final Duration batasWaktuTunggu;
  final FeedLokalService penyimpananLokal;

  const SupabaseFeedService({
    this.batasWaktuTunggu = const Duration(seconds: 10),
    this.penyimpananLokal = const FeedLokalService(),
    super.lamaResponServer = Duration.zero,
  });

  static bool apakahMasalahKoneksi(Object galat) {
    if (galat is TimeoutException) return true;
    if (galat is AuthRetryableFetchException && galat.statusCode == null) {
      return true;
    }

    String teksGalat = galat.toString().toLowerCase();
    return cirinyaTidakAdaInternet.any((ciri) => teksGalat.contains(ciri));
  }

  String idPenggunaAktif() {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? 'tamu';
    } catch (_) {
      return 'tamu';
    }
  }

  @override
  Future<FeedBeranda> ambilFeedBeranda() async {
    String idPengguna = idPenggunaAktif();

    try {
      FeedBeranda feedDariServer = await ambilDariServer();
      await penyimpananLokal.simpanFeed(idPengguna, feedDariServer);
      return feedDariServer;
    } catch (galat) {
      bool isKarenaOffline = apakahMasalahKoneksi(galat);

      FeedBeranda? feedTerakhir = await penyimpananLokal.ambilFeed(idPengguna);
      if (feedTerakhir != null) {
        return feedTerakhir.tandaiAsal(
          AsalFeed.simpananTerakhir,
          isKarenaOffline: isKarenaOffline,
        );
      }

      FeedBeranda feedContoh = await super.ambilFeedBeranda();
      return feedContoh.tandaiAsal(
        AsalFeed.contoh,
        isKarenaOffline: isKarenaOffline,
      );
    }
  }

  Future<FeedBeranda> ambilDariServer() async {
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

  @override
  Future<void> catatRiwayatPutar(Lagu lagu) async {
    try {
      SupabaseClient klienSupabase = Supabase.instance.client;
      if (klienSupabase.auth.currentUser == null) return;

      Map<String, dynamic>? barisLagu = await klienSupabase
          .from(namaTabelLagu)
          .select('id')
          .eq('title', lagu.judul)
          .eq('artist', lagu.penyanyi)
          .limit(1)
          .maybeSingle()
          .timeout(batasWaktuTunggu);
      if (barisLagu == null) return;

      await klienSupabase
          .from(namaTabelRiwayat)
          .insert({'track_id': barisLagu['id']})
          .timeout(batasWaktuTunggu);
    } catch (_) {
      return;
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
