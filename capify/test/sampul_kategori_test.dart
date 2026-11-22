import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capify/data/lagu_per_kategori_dummy.dart';
import 'package:capify/screens/explore_screen.dart';
import 'package:capify/widgets/sampul_kategori.dart';

void main() {
  test('Sampul kategori diambil dari cover lagu pertama', () {
    expect(
      ambilUrlSampulKategori('Pop'),
      laguPerKategoriDummy['Pop']!.first.urlCover,
    );
    expect(ambilUrlSampulKategori('Podcast'), isNull);
    expect(ambilUrlSampulKategori('Kategori Asal'), isNull);
  });

  test('Gambar di-decode seukuran tampilan, bukan ukuran aslinya', () {
    expect(hitungLebarDecode(3.0), 204);
    expect(hitungLebarDecode(2.625), 179);
    expect(hitungLebarDecode(1.0), 68);
    expect(hitungLebarDecode(0), 68);
  });

  test('Precache dan widget memakai kunci cache yang sama', () {
    const String url = 'https://picsum.photos/seed/tes/400';

    expect(buatPenyediaSampul(url, 3.0), buatPenyediaSampul(url, 3.0));
    expect(
      buatPenyediaSampul(url, 3.0) == buatPenyediaSampul(url, 2.0),
      isFalse,
    );
  });

  testWidgets('Kategori tanpa lagu cukup menampilkan ikon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: ukuranSampulKategori,
          height: ukuranSampulKategori,
          child: SampulKategori(
            urlSampul: null,
            ikonCadangan: Icons.podcasts_rounded,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.podcasts_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Gambar gagal dimuat tetap menyisakan ikon tanpa crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: ukuranSampulKategori,
          height: ukuranSampulKategori,
          child: SampulKategori(
            urlSampul: 'https://contoh.invalid/rusak.jpg',
            ikonCadangan: Icons.star_rounded,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Grid explore memakai gambar kecil untuk kategori yang ada lagunya',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      Finder gambarDiKartuPop = find.descendant(
        of: find.byKey(const ValueKey('Pop')),
        matching: find.byType(Image),
      );
      expect(gambarDiKartuPop, findsOneWidget);

      Image gambarPop = tester.widget(gambarDiKartuPop);
      ResizeImage penyediaGambar = gambarPop.image as ResizeImage;
      expect(
        penyediaGambar.width,
        hitungLebarDecode(tester.view.devicePixelRatio),
      );

      expect(find.byKey(const ValueKey('Podcast')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('Podcast')),
          matching: find.byType(Image),
        ),
        findsNothing,
      );
    },
  );
}
