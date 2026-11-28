import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/home_provider.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/screens/home_screen.dart';
import 'package:capify/screens/player_screen.dart';
import 'package:capify/services/feed_service.dart';
import 'package:capify/services/supabase_feed_service.dart';
import 'package:capify/widgets/komponen_beranda.dart';

import 'feed_server_palsu.dart';
import 'pemutar_audio_palsu.dart';

Widget bungkusHalamanBeranda(AudioProvider audio, HomeProvider home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: audio),
      ChangeNotifierProvider.value(value: home),
      ChangeNotifierProvider(create: (context) => PlaylistProvider()),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  late AudioProvider audio;
  late HomeProvider home;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

  testWidgets('Spanduk offline memberi tahu beranda terakhir tersimpan', (
    tester,
  ) async {
    FeedServerPalsu server = FeedServerPalsu([
      null,
      FeedServerPalsu.galatOffline(),
    ]);
    HomeProvider homeOffline = HomeProvider(feedService: server);
    addTearDown(homeOffline.dispose);

    await tester.pumpWidget(bungkusHalamanBeranda(audio, homeOffline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SpandukDataCadangan), findsNothing);

    await tester.runAsync(
      () => homeOffline.muatIsiBeranda(isPaksaMuatUlang: true),
    );
    await tester.pump();

    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.textContaining('Kamu sedang offline'), findsOneWidget);
    expect(find.textContaining('berandamu dari baru saja'), findsOneWidget);
    expect(find.text('Evaluasi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Masih offline'), findsOneWidget);
  });

  testWidgets('Beranda mencoba lagi otomatis saat aplikasi dibuka kembali', (
    tester,
  ) async {
    FeedServerPalsu server = FeedServerPalsu([
      FeedServerPalsu.galatOffline(),
      null,
    ]);
    HomeProvider homeOffline = HomeProvider(feedService: server);
    addTearDown(homeOffline.dispose);

    await tester.pumpWidget(bungkusHalamanBeranda(audio, homeOffline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('lagu contoh'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(server.jumlahPanggilanServer, 2);
    expect(find.byType(SpandukDataCadangan), findsNothing);
    expect(find.textContaining('kembali online'), findsOneWidget);
  });

  Finder areaGeserBeranda() {
    return find
        .descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byType(Scrollable),
        )
        .first;
  }

  testWidgets('Tarik ke bawah memberi tahu beranda sudah diperbarui', (
    tester,
  ) async {
    HomeProvider homeUji = HomeProvider(
      feedService: const FeedService(lamaResponServer: Duration.zero),
    );
    addTearDown(homeUji.dispose);

    await tester.pumpWidget(bungkusHalamanBeranda(audio, homeUji));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Diperbarui baru saja'), findsOneWidget);

    await tester.drag(areaGeserBeranda(), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(find.text('Beranda sudah diperbarui'), findsOneWidget);
  });

  group('Putar langsung dari feed', () {
    Future<void> bukaBerandaSiap(
      WidgetTester tester,
      HomeProvider homeUji,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(bungkusHalamanBeranda(audio, homeUji));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    Finder kartuLagu(String judul) {
      return find.widgetWithText(KartuLaguKecil, judul);
    }

    testWidgets('Ketuk lagu langsung memutar tanpa membuka player', (
      tester,
    ) async {
      await bukaBerandaSiap(tester, home);
      await tester.scrollUntilVisible(
        kartuLagu('One Call Away'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(kartuLagu('One Call Away'));
      await tester.pump();

      await tester.tap(kartuLagu('One Call Away'));
      await tester.pump();

      expect(audio.laguSekarang?.judul, 'One Call Away');
      expect(audio.namaAntrian, 'Temuan Baru dari Capy');
      expect(find.byType(PlayerScreen), findsNothing);
      expect(
        find.descendant(
          of: kartuLagu('One Call Away'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 800));
      expect(audio.isLaguSedangDiputar, isTrue);
      expect(home.laguUntukDilanjutkan?.lagu.judul, 'One Call Away');
    });

    testWidgets('Ketuk lagu yang sedang aktif membuka player layar penuh', (
      tester,
    ) async {
      await bukaBerandaSiap(tester, home);

      await tester.tap(find.byType(KartuLanjutDengerin));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(PlayerScreen), findsNothing);
      expect(audio.laguSekarang?.judul, 'Evaluasi');

      await tester.tap(find.byType(KartuLanjutDengerin));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('Tombol putar racikan memutar lalu menjeda racikannya', (
      tester,
    ) async {
      await bukaBerandaSiap(tester, home);
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Putar Racikan Pop'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.bySemanticsLabel('Putar Racikan Pop'));
      await tester.pump(const Duration(milliseconds: 800));

      expect(audio.namaAntrian, 'Racikan Pop');
      expect(audio.isLaguSedangDiputar, isTrue);
      expect(find.bySemanticsLabel('Jeda Racikan Pop'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Jeda Racikan Pop'));
      await tester.pump();

      expect(audio.isLaguSedangDiputar, isFalse);
      expect(find.bySemanticsLabel('Putar Racikan Pop'), findsOneWidget);
    });

    testWidgets('Memutar saat offline memberi peringatan singkat', (
      tester,
    ) async {
      HomeProvider homeOffline = HomeProvider(
        feedService: FeedServerPalsu([FeedServerPalsu.galatOffline()]),
      );
      addTearDown(homeOffline.dispose);
      await bukaBerandaSiap(tester, homeOffline);

      await tester.tap(find.byType(KartuLanjutDengerin));
      await tester.pump();

      expect(find.textContaining('lagu mungkin gagal diputar'), findsOneWidget);
      expect(audio.laguSekarang?.judul, 'Evaluasi');

      await tester.pump(const Duration(milliseconds: 800));
    });
  });
}
