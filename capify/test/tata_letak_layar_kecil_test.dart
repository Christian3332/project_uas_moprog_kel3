import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/home_provider.dart';
import 'package:capify/screens/home_screen.dart';
import 'package:capify/screens/onboarding_screen.dart';
import 'package:capify/screens/preferensi_genre_screen.dart';
import 'package:capify/services/feed_service.dart';
import 'package:capify/widgets/komponen_beranda.dart';

import 'feed_server_palsu.dart';
import 'pemutar_audio_palsu.dart';

class UkuranUji {
  final String nama;
  final Size ukuranLayar;
  final double skalaHuruf;

  const UkuranUji(this.nama, this.ukuranLayar, this.skalaHuruf);
}

const List<UkuranUji> daftarUkuranUji = [
  UkuranUji('HP mungil 280x600 huruf 2x', Size(280, 600), 2.0),
  UkuranUji('HP kecil 320x568 huruf 1.6x', Size(320, 568), 1.6),
  UkuranUji('landscape 640x320 huruf 2x', Size(640, 320), 2.0),
];

void main() {
  late AudioProvider audio;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    audio = AudioProvider(pemutarAudio: PemutarAudioPalsu());
  });

  tearDown(() {
    audio.dispose();
  });

  Future<void> pasangHalaman(
    WidgetTester tester,
    UkuranUji ukuran,
    HomeProvider home,
    Widget halaman,
  ) async {
    tester.view.physicalSize = ukuran.ukuranLayar * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: audio),
          ChangeNotifierProvider.value(value: home),
        ],
        child: MaterialApp(
          builder: (context, anak) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(ukuran.skalaHuruf)),
            child: anak!,
          ),
          home: halaman,
        ),
      ),
    );
  }

  for (UkuranUji ukuran in daftarUkuranUji) {
    group(ukuran.nama, () {
      testWidgets('Beranda tidak meluap sampai bagian paling bawah', (
        tester,
      ) async {
        HomeProvider home = HomeProvider(
          feedService: const FeedService(lamaResponServer: Duration.zero),
        );
        addTearDown(home.dispose);
        await pasangHalaman(
          tester,
          ukuran,
          home,
          const HomeScreen(namaPengguna: 'Capy Lovers Sejati Banget'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.scrollUntilVisible(
          find.text('Belum pernah kamu dengar'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();

        expect(find.byType(KartuLaguKecil), findsWidgets);
      });

      testWidgets('Kerangka memuat dan spanduk offline tidak meluap', (
        tester,
      ) async {
        HomeProvider home = HomeProvider(
          feedService: FeedServerPalsu([FeedServerPalsu.galatOffline()]),
        );
        addTearDown(home.dispose);
        await pasangHalaman(tester, ukuran, home, const HomeScreen());

        expect(find.byType(KerangkaBerandaMemuat), findsOneWidget);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SpandukDataCadangan), findsOneWidget);
      });

      testWidgets('Onboarding tidak meluap di semua slide', (tester) async {
        HomeProvider home = HomeProvider();
        addTearDown(home.dispose);
        await pasangHalaman(tester, ukuran, home, const OnboardingScreen());

        for (int nomorSlide = 0; nomorSlide < 2; nomorSlide++) {
          await tester.tap(find.text('Lanjut'));
          await tester.pumpAndSettle();
        }

        expect(find.text('Mulai Sekarang'), findsOneWidget);
      });

      testWidgets('Genre paling bawah tetap bisa dipilih', (tester) async {
        HomeProvider home = HomeProvider();
        addTearDown(home.dispose);
        await pasangHalaman(
          tester,
          ukuran,
          home,
          const PreferensiGenreScreen(isDariOnboarding: true),
        );

        await tester.scrollUntilVisible(
          find.text('Santai'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Santai'));
        await tester.pump();
        await tester.tap(find.text('Santai'));
        await tester.pump();

        expect(find.text('1 dari 5 genre dipilih'), findsOneWidget);
      });
    });
  }
}
