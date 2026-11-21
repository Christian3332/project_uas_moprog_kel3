import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/providers/search_provider.dart';
import 'package:capify/screens/search_screen.dart';
import 'package:capify/services/search_service.dart';

const String trackTanpaCover = '''
[
  {"id": "t1", "title": "Starboy", "artist": "The Weeknd", "duration_ms": 230000},
  {"id": "t2", "title": "Lights Up", "artist": "Harry Styles", "duration_ms": 172000}
]
''';

Future<void> bukaLayarCari(WidgetTester tester) async {
  SearchProvider pencarian = SearchProvider(
    searchService: SearchService(
      lamaMenunggu: Duration.zero,
      responsTrackKhusus: trackTanpaCover,
      responsAlbumServer: '[]',
    ),
    jedaSetelahMengetik: Duration.zero,
    kamusSaranEjaan: ['The Weeknd', 'Starboy', 'Harry Styles', 'Lights Up'],
  );

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: pencarian,
      child: const MaterialApp(home: SearchScreen()),
    ),
  );
}

Future<void> ketikLaluTunggu(WidgetTester tester, String ketikan) async {
  await tester.enterText(find.byType(TextField), ketikan);
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Salah ketik menampilkan saran dan saran bisa langsung dipakai', (
    tester,
  ) async {
    await bukaLayarCari(tester);

    await ketikLaluTunggu(tester, 'weekend');

    expect(find.text('Tidak ada hasil untuk "weekend"'), findsOneWidget);
    expect(find.text('Mungkin maksudmu'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'The Weeknd'));
    await tester.pumpAndSettle();

    expect(find.text('1 lagu ditemukan'), findsOneWidget);
    expect(find.text('Mungkin maksudmu'), findsNothing);
  });

  testWidgets('Filter yang menyembunyikan hasil memberi tahu jumlahnya', (
    tester,
  ) async {
    await bukaLayarCari(tester);
    await ketikLaluTunggu(tester, 'starboy');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Penyanyi'));
    await tester.pumpAndSettle();

    expect(find.text('Lihat 1 hasil'), findsOneWidget);

    await tester.tap(find.text('Lihat 1 hasil'));
    await tester.pumpAndSettle();
    expect(find.text('1 lagu ditemukan'), findsOneWidget);
  });

  testWidgets('Kata kunci panjang tanpa hasil menawarkan cari satu kata', (
    tester,
  ) async {
    await bukaLayarCari(tester);

    await ketikLaluTunggu(tester, 'lights capybara');

    expect(find.text('Cari "lights" saja'), findsOneWidget);
    expect(
      find.text('Pakai kata yang lebih sedikit atau lebih umum'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Hapus pencarian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus pencarian'));
    await tester.pumpAndSettle();
    expect(find.text('Cari lagu atau penyanyi favoritmu'), findsOneWidget);
  });

  testWidgets('Tombol X mengosongkan kolom, hasil, dan filter', (tester) async {
    await bukaLayarCari(tester);
    await ketikLaluTunggu(tester, 'starboy');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Judul'));
    await tester.pumpAndSettle();
    expect(find.text('1 lagu ditemukan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    TextField kolomCari = tester.widget(find.byType(TextField));
    expect(kolomCari.controller!.text, isEmpty);
    expect(find.text('1 lagu ditemukan'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Cari lagu atau penyanyi favoritmu'), findsOneWidget);

    await ketikLaluTunggu(tester, 'harry');
    ChoiceChip chipSemua = tester.widget(
      find.widgetWithText(ChoiceChip, 'Semua'),
    );
    expect(chipSemua.selected, isTrue);
  });

  testWidgets('Menghapus teks sampai habis langsung membersihkan hasil', (
    tester,
  ) async {
    await bukaLayarCari(tester);
    await ketikLaluTunggu(tester, 'weekend');
    expect(find.text('Mungkin maksudmu'), findsOneWidget);

    await ketikLaluTunggu(tester, '');

    expect(find.text('Mungkin maksudmu'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.text('Cari lagu atau penyanyi favoritmu'), findsOneWidget);
  });
}
