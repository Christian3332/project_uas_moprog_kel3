import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/home_provider.dart';
import 'package:capify/screens/home_screen.dart';
import 'package:capify/widgets/komponen_beranda.dart';

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
    audio = AudioProvider();
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
}
