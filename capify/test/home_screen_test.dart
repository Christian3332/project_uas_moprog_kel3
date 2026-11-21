import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/home_provider.dart';
import 'package:capify/screens/home_screen.dart';
import 'package:capify/services/feed_service.dart';
import 'package:capify/services/supabase_feed_service.dart';
import 'package:capify/widgets/komponen_beranda.dart';

import 'pemutar_audio_palsu.dart';

Widget bungkusHalamanBeranda(AudioProvider audio, HomeProvider home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: audio),
      ChangeNotifierProvider.value(value: home),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  late AudioProvider audio;
  late HomeProvider home;

  setUp(() {
    audio = AudioProvider(pemutarAudio: PemutarAudioPalsu());
    home = HomeProvider();
  });

  tearDown(() {
    home.dispose();
    audio.dispose();
  });

  Finder diDalamKartuLanjutan(Finder yangDicari) {
    return find.descendant(
      of: find.byType(KartuLanjutDengerin),
      matching: yangDicari,
    );
  }

  testWidgets('Beranda menampilkan loading lalu isi feed', (tester) async {
    await tester.pumpWidget(bungkusHalamanBeranda(audio, home));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Lanjut dengerin'), findsOneWidget);
    expect(find.text('Evaluasi'), findsOneWidget);
    expect(find.text('Racikan untukmu'), findsOneWidget);
  });

  testWidgets('Tombol di kartu lanjutan mengikuti status pemutar', (
    tester,
  ) async {
    await tester.pumpWidget(bungkusHalamanBeranda(audio, home));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(
      diDalamKartuLanjutan(find.byIcon(Icons.play_arrow_rounded)),
    );
    await tester.pump();
    expect(
      diDalamKartuLanjutan(find.byType(CircularProgressIndicator)),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Sedang diputar'), findsOneWidget);
    expect(
      diDalamKartuLanjutan(find.byIcon(Icons.pause_rounded)),
      findsOneWidget,
    );
    expect(home.riwayatTerakhirDiputar.length, 6);
    expect(audio.laguSekarang?.judul, 'Evaluasi');

    await tester.tap(diDalamKartuLanjutan(find.byIcon(Icons.pause_rounded)));
    await tester.pump();
    expect(find.text('Lanjut dengerin'), findsOneWidget);
    expect(audio.isLaguSedangDiputar, isFalse);
  });

  testWidgets('Beranda menampilkan pesan dan tombol coba lagi saat gagal', (
    tester,
  ) async {
    HomeProvider homeGagal = HomeProvider(
      feedService: const FeedService(
        lamaResponServer: Duration.zero,
        isSimulasiGagal: true,
      ),
    );
    addTearDown(homeGagal.dispose);

    await tester.pumpWidget(bungkusHalamanBeranda(audio, homeGagal));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('feed belum bisa diambil'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('Spanduk muncul saat beranda memakai data cadangan', (
    tester,
  ) async {
    HomeProvider homeSupabase = HomeProvider(
      feedService: const SupabaseFeedService(),
    );
    addTearDown(homeSupabase.dispose);

    await tester.pumpWidget(bungkusHalamanBeranda(audio, homeSupabase));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SpandukDataCadangan), findsOneWidget);
    expect(find.text('Evaluasi'), findsOneWidget);
  });

  testWidgets('Spanduk tidak muncul untuk data biasa', (tester) async {
    await tester.pumpWidget(bungkusHalamanBeranda(audio, home));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SpandukDataCadangan), findsNothing);
  });

  testWidgets('Kerangka beranda tampil saat muat pertama lalu hilang', (
    tester,
  ) async {
    await tester.pumpWidget(bungkusHalamanBeranda(audio, home));

    expect(find.byType(KerangkaBerandaMemuat), findsOneWidget);
    expect(find.text('Menyiapkan berandamu...'), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(KerangkaBerandaMemuat), findsNothing);
    expect(find.byType(KartuLanjutDengerin), findsOneWidget);
  });

  testWidgets('Pesan koneksi lambat muncul kalau server kelamaan', (
    tester,
  ) async {
    HomeProvider homeLambat = HomeProvider(
      feedService: const FeedService(lamaResponServer: Duration(seconds: 3)),
      batasSabarMenunggu: const Duration(seconds: 1),
    );
    addTearDown(homeLambat.dispose);

    await tester.pumpWidget(bungkusHalamanBeranda(audio, homeLambat));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Koneksi lagi lambat'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(KerangkaBerandaMemuat), findsNothing);
    expect(find.text('Evaluasi'), findsOneWidget);
  });

  testWidgets('Tombol coba lagi di spanduk menampilkan progres dan pesan', (
    tester,
  ) async {
    HomeProvider homeSupabase = HomeProvider(
      feedService: const SupabaseFeedService(),
    );
    addTearDown(homeSupabase.dispose);

    await tester.pumpWidget(bungkusHalamanBeranda(audio, homeSupabase));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(SpandukDataCadangan),
        matching: find.text('Coba lagi'),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SpandukDataCadangan),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('masih belum bisa dihubungi'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
