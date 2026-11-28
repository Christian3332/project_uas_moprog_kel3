import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:capify/models/feed_beranda.dart';
import 'package:capify/services/supabase_feed_service.dart';

import 'feed_server_palsu.dart';

void main() {
  DateTime waktuPatokan = DateTime.utc(2026, 11, 20, 12, 0);

  List<Map<String, dynamic>> barisLaguContoh = [
    {
      'id': 'feed-001',
      'title': 'Evaluasi',
      'artist': 'Hindia',
      'cover_url': '',
      'audio_url': 'https://contoh.capify.id/evaluasi.mp3',
      'duration_ms': 227000,
      'genre': 'Indie',
    },
    {
      'id': 'feed-002',
      'title': 'Ditto',
      'artist': 'NewJeans',
      'cover_url': '',
      'audio_url': '',
      'duration_ms': 185000,
      'genre': 'K-Pop',
    },
  ];

  test('Waktu diputar diubah jadi menit yang lalu', () {
    Map<String, dynamic> json = SupabaseFeedService.susunJsonFeed(
      barisLaguContoh,
      [
        {'track_id': 'feed-002', 'played_at': '2026-11-20T11:15:00Z'},
        {'track_id': 'feed-001', 'played_at': '2026-11-19T12:00:00Z'},
      ],
      waktuPatokan,
    );

    FeedBeranda feed = FeedBeranda.fromJson(json);

    expect(feed.riwayatPutar.length, 2);
    expect(feed.riwayatPutar[0].lagu.judul, 'Ditto');
    expect(feed.riwayatPutar[0].teksWaktuDiputar, '45 menit lalu');
    expect(feed.riwayatPutar[1].teksWaktuDiputar, 'Kemarin');
    expect(
      feed.laguPerGenre['Indie']?.first.urlAudio,
      'https://contoh.capify.id/evaluasi.mp3',
    );
  });

  test('Lagu yang diputar berkali-kali hanya diambil yang terbaru', () {
    Map<String, dynamic> json = SupabaseFeedService.susunJsonFeed(
      barisLaguContoh,
      [
        {'track_id': 'feed-001', 'played_at': '2026-11-20T11:50:00Z'},
        {'track_id': 'feed-001', 'played_at': '2026-11-20T08:00:00Z'},
        {'track_id': 'feed-001', 'played_at': '2026-11-18T08:00:00Z'},
      ],
      waktuPatokan,
    );

    List<dynamic> riwayat = json['recently_played'];
    expect(riwayat.length, 1);
    expect(riwayat.first['played_minutes_ago'], 10);
  });

  test('Supabase belum siap maka feed cadangan yang dipakai', () async {
    FeedBeranda feed = await const SupabaseFeedService().ambilFeedBeranda();

    expect(feed.isDariCadangan, isTrue);
    expect(feed.jumlahLaguDiKatalog, 11);
    expect(feed.riwayatPutar, isNotEmpty);
  });

  group('Kondisi offline', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Galat jaringan dikenali sebagai offline', () {
      expect(
        SupabaseFeedService.apakahMasalahKoneksi(TimeoutException('lama')),
        isTrue,
      );
      expect(
        SupabaseFeedService.apakahMasalahKoneksi(
          Exception('ClientException: XMLHttpRequest error.'),
        ),
        isTrue,
      );
      expect(
        SupabaseFeedService.apakahMasalahKoneksi(
          Exception('SocketException: Failed host lookup: abc.supabase.co'),
        ),
        isTrue,
      );
      expect(
        SupabaseFeedService.apakahMasalahKoneksi(
          Exception('relation "public.tracks" does not exist'),
        ),
        isFalse,
      );
    });

    test('Feed dari server disimpan untuk dipakai saat offline', () async {
      FeedServerPalsu server = FeedServerPalsu([
        null,
        FeedServerPalsu.galatOffline(),
      ]);

      FeedBeranda feedOnline = await server.ambilFeedBeranda();
      FeedBeranda feedOffline = await server.ambilFeedBeranda();

      expect(feedOnline.asalFeed, AsalFeed.server);
      expect(feedOffline.asalFeed, AsalFeed.simpananTerakhir);
      expect(feedOffline.isKarenaOffline, isTrue);
      expect(feedOffline.waktuDisimpan, isNotNull);
      expect(feedOffline.riwayatPutar.first.lagu.judul, 'Evaluasi');
    });

    test('Offline tanpa simpanan memakai lagu contoh', () async {
      FeedServerPalsu server = FeedServerPalsu([
        FeedServerPalsu.galatOffline(),
      ]);

      FeedBeranda feed = await server.ambilFeedBeranda();

      expect(feed.asalFeed, AsalFeed.contoh);
      expect(feed.isKarenaOffline, isTrue);
      expect(feed.jumlahLaguDiKatalog, 11);
    });

    test('Server bermasalah tidak dianggap offline', () async {
      FeedServerPalsu server = FeedServerPalsu([FeedServerPalsu.galatServer()]);

      FeedBeranda feed = await server.ambilFeedBeranda();

      expect(feed.isDariCadangan, isTrue);
      expect(feed.isKarenaOffline, isFalse);
    });
  });
}
