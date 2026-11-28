import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/feed_beranda.dart';
import 'package:capify/services/feed_service.dart';

void main() {
  const FeedService serviceCepat = FeedService(lamaResponServer: Duration.zero);

  test('Feed dummy berisi riwayat dan katalog per genre', () async {
    FeedBeranda feed = await serviceCepat.ambilFeedBeranda();

    expect(feed.riwayatPutar.length, 6);
    expect(feed.riwayatPutar.first.lagu.judul, 'Evaluasi');
    expect(feed.riwayatPutar.first.teksWaktuDiputar, '4 menit lalu');
    expect(feed.laguPerGenre.keys, [
      'Pop',
      'Indie',
      'K-Pop',
      'R&B',
      'Jazz',
      'Lo-Fi',
    ]);
    expect(feed.jumlahLaguDiKatalog, 11);
  });

  test('Simulasi gagal melempar pesan yang jelas', () async {
    const FeedService serviceGagal = FeedService(
      lamaResponServer: Duration.zero,
      isSimulasiGagal: true,
    );

    expect(
      serviceGagal.ambilFeedBeranda(),
      throwsA(
        predicate((error) => error.toString().contains('feed belum bisa')),
      ),
    );
  });

  test('JSON rusak dan bentuk asing ditolak', () {
    expect(
      () => FeedService.ubahJsonKeFeed('{tracks: ['),
      throwsA(predicate((error) => error.toString().contains('rusak'))),
    );
    expect(
      () => FeedService.ubahJsonKeFeed('[1, 2, 3]'),
      throwsA(predicate((error) => error.toString().contains('dikenali'))),
    );
  });

  test('Riwayat dengan id lagu asing dilewati tanpa crash', () {
    FeedBeranda feed = FeedService.ubahJsonKeFeed('''
{
  "tracks": [
    {"id": "a", "title": "Lagu A", "artist": "Capy", "duration_ms": 1000, "genre": "Pop"},
    {"id": "a", "title": "Lagu A Dobel", "artist": "Capy", "duration_ms": 1000, "genre": "Pop"},
    {"title": "Tanpa Id", "artist": "Capy", "genre": "Pop"},
    "bukan objek"
  ],
  "recently_played": [
    {"track_id": "a", "played_minutes_ago": -5},
    {"track_id": "tidak-ada", "played_minutes_ago": 3},
    {"played_minutes_ago": 3}
  ]
}
''');

    expect(feed.jumlahLaguDiKatalog, 1);
    expect(feed.riwayatPutar.length, 1);
    expect(feed.riwayatPutar.first.teksWaktuDiputar, 'Baru saja');
  });
}
