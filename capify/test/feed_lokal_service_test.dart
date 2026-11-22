import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:capify/models/feed_beranda.dart';
import 'package:capify/services/feed_lokal_service.dart';
import 'package:capify/services/feed_service.dart';

void main() {
  const FeedLokalService penyimpanan = FeedLokalService();
  late FeedBeranda feedContoh;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    feedContoh = FeedService.ubahJsonKeFeed(FeedService.responsServerDummy);
  });

  test('Feed yang disimpan bisa diambil lagi sebagai simpanan', () async {
    DateTime waktuSimpan = DateTime(2026, 11, 22, 10, 0);
    await penyimpanan.simpanFeed('usr-1', feedContoh, waktuSimpan: waktuSimpan);

    FeedBeranda? feedTersimpan = await penyimpanan.ambilFeed(
      'usr-1',
      waktuSekarang: waktuSimpan,
    );

    expect(feedTersimpan, isNotNull);
    expect(feedTersimpan!.asalFeed, AsalFeed.simpananTerakhir);
    expect(feedTersimpan.waktuDisimpan, waktuSimpan);
    expect(feedTersimpan.jumlahLaguDiKatalog, 11);
    expect(feedTersimpan.riwayatPutar.first.teksWaktuDiputar, '4 menit lalu');
  });

  test('Waktu riwayat ikut bertambah sesuai lamanya tersimpan', () async {
    DateTime waktuSimpan = DateTime(2026, 11, 22, 10, 0);
    await penyimpanan.simpanFeed('usr-1', feedContoh, waktuSimpan: waktuSimpan);

    FeedBeranda? feedTersimpan = await penyimpanan.ambilFeed(
      'usr-1',
      waktuSekarang: waktuSimpan.add(const Duration(hours: 2)),
    );

    expect(feedTersimpan!.riwayatPutar.first.teksWaktuDiputar, '2 jam lalu');
  });

  test('Simpanan tiap akun terpisah', () async {
    await penyimpanan.simpanFeed('usr-1', feedContoh);

    expect(await penyimpanan.ambilFeed('usr-2'), isNull);
    expect(await penyimpanan.ambilFeed('usr-1'), isNotNull);
    expect(penyimpanan.kunciUntuk('  '), '${FeedLokalService.awalanKunci}tamu');
  });

  test('Data rusak di penyimpanan dibuang tanpa crash', () async {
    SharedPreferences.setMockInitialValues({
      '${FeedLokalService.awalanKunci}usr-1': '{ini bukan json',
    });

    expect(await penyimpanan.ambilFeed('usr-1'), isNull);

    SharedPreferences data = await SharedPreferences.getInstance();
    expect(data.containsKey('${FeedLokalService.awalanKunci}usr-1'), isFalse);
  });

  test('Feed tanpa katalog tidak ikut disimpan', () async {
    await penyimpanan.simpanFeed(
      'usr-1',
      const FeedBeranda(riwayatPutar: [], laguPerGenre: {}),
    );

    expect(await penyimpanan.ambilFeed('usr-1'), isNull);
  });
}
