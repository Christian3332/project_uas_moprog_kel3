import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/providers/home_provider.dart';
import 'package:capify/screens/preferensi_genre_screen.dart';

void main() {
  late HomeProvider home;
  bool? hasilDariHalamanPreferensi;

  setUp(() {
    home = HomeProvider();
    hasilDariHalamanPreferensi = null;
  });

  tearDown(() {
    home.dispose();
  });

  Future<void> bukaHalamanPreferensi(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: home,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      hasilDariHalamanPreferensi = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PreferensiGenreScreen(),
                        ),
                      );
                    },
                    child: const Text('Buka preferensi'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka preferensi'));
    await tester.pumpAndSettle();
  }

  Finder nomorDiKartu(String namaGenre, String nomor) {
    return find.descendant(
      of: find.widgetWithText(KartuPilihanGenre, namaGenre),
      matching: find.text(nomor),
    );
  }

  testWidgets('Tombol simpan mati sebelum ada genre dipilih', (tester) async {
    await bukaHalamanPreferensi(tester);

    ElevatedButton tombolSimpan = tester.widget(
      find.widgetWithText(ElevatedButton, 'Simpan Preferensi'),
    );
    expect(tombolSimpan.onPressed, isNull);
    expect(find.text('Belum ada genre yang dipilih'), findsOneWidget);
  });

  testWidgets('Nomor urut genre ikut maju saat salah satu dibatalkan', (
    tester,
  ) async {
    await bukaHalamanPreferensi(tester);

    await tester.tap(find.text('Pop'));
    await tester.tap(find.text('Jazz'));
    await tester.pump();
    expect(nomorDiKartu('Pop', '1'), findsOneWidget);
    expect(nomorDiKartu('Jazz', '2'), findsOneWidget);

    await tester.tap(find.text('Pop'));
    await tester.pump();
    expect(nomorDiKartu('Jazz', '1'), findsOneWidget);
    expect(find.text('1 dari 5 genre dipilih'), findsOneWidget);
  });

  testWidgets('Tidak bisa memilih lebih dari lima genre', (tester) async {
    await bukaHalamanPreferensi(tester);

    for (String genre in ['Pop', 'Indie', 'K-Pop', 'R&B', 'Jazz', 'Lo-Fi']) {
      await tester.tap(find.text(genre));
      await tester.pump();
    }

    expect(find.textContaining('Maksimal 5 genre'), findsOneWidget);
    expect(find.text('5 dari 5 genre dipilih'), findsOneWidget);
  });

  testWidgets('Pilihan tersimpan ke HomeProvider lalu kembali', (tester) async {
    await bukaHalamanPreferensi(tester);

    await tester.tap(find.text('Indie'));
    await tester.tap(find.text('Jazz'));
    await tester.pump();
    await tester.tap(find.text('Simpan Preferensi'));
    await tester.pumpAndSettle();

    expect(home.genreFavorit, ['Indie', 'Jazz']);
    expect(hasilDariHalamanPreferensi, isTrue);
    expect(find.text('Buka preferensi'), findsOneWidget);
  });

  testWidgets('Pilihan lama langsung terlihat saat halaman dibuka lagi', (
    tester,
  ) async {
    home.simpanGenreFavorit(['R&B', 'Pop']);

    await bukaHalamanPreferensi(tester);

    expect(nomorDiKartu('R&B', '1'), findsOneWidget);
    expect(nomorDiKartu('Pop', '2'), findsOneWidget);
  });
}
