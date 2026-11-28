import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/screens/playlist_screen.dart';
import 'package:capify/services/koleksi_service.dart';
import 'package:capify/widgets/cover_album.dart';

import 'pemutar_audio_palsu.dart';

class UkuranLayarUji {
  final String nama;
  final Size ukuranLayar;
  final double skalaHuruf;

  const UkuranLayarUji(this.nama, this.ukuranLayar, this.skalaHuruf);
}

const List<UkuranLayarUji> daftarUkuranUji = [
  UkuranLayarUji('HP biasa 393x852', Size(393, 852), 1.0),
  UkuranLayarUji('tablet 600x900', Size(600, 900), 1.0),
  UkuranLayarUji('HP mungil 280x600 huruf 2x', Size(280, 600), 2.0),
  UkuranLayarUji('HP kecil 320x568 huruf 1.6x', Size(320, 568), 1.6),
  UkuranLayarUji('landscape 640x320 huruf 2x', Size(640, 320), 2.0),
];

void main() {
  Future<void> bukaTabKoleksi(
    WidgetTester tester,
    UkuranLayarUji ukuran,
    String namaTab,
  ) async {
    tester.view.physicalSize = ukuran.ukuranLayar;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) =>
                AudioProvider(pemutarAudio: PemutarAudioPalsu()),
          ),
          ChangeNotifierProvider(
            create: (context) => PlaylistProvider(
              koleksiService: const KoleksiService(
                lamaResponServer: Duration.zero,
              ),
            )..muatKoleksi(),
          ),
        ],
        child: MaterialApp(
          builder: (context, anak) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(ukuran.skalaHuruf)),
            child: anak!,
          ),
          home: const PlaylistScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text(namaTab));
    await tester.pumpAndSettle();
  }

  for (UkuranLayarUji ukuran in daftarUkuranUji) {
    for (String namaTab in ['Album', 'Lagu Disukai']) {
      testWidgets(
        '${ukuran.nama}: cover $namaTab persegi dan teks tidak meluap',
        (tester) async {
          await bukaTabKoleksi(tester, ukuran, namaTab);

          Finder semuaKartu = find.byType(KartuGridKoleksi);
          expect(semuaKartu, findsWidgets);

          for (Element kartu in semuaKartu.evaluate()) {
            Finder kartuIni = find.byElementPredicate(
              (elemen) => elemen == kartu,
            );
            Rect kotakKartu = tester.getRect(kartuIni);
            Rect kotakCover = tester.getRect(
              find.descendant(of: kartuIni, matching: find.byType(CoverAlbum)),
            );
            Rect kotakTeksTerakhir = tester.getRect(
              find.descendant(of: kartuIni, matching: find.byType(Text)).last,
            );

            expect(kotakCover.width, closeTo(kotakCover.height, 0.5));
            expect(kotakCover.left, closeTo(kotakKartu.left, 0.5));
            expect(kotakCover.width, lessThanOrEqualTo(kotakKartu.width + 0.5));
            expect(
              kotakTeksTerakhir.bottom,
              lessThanOrEqualTo(kotakKartu.bottom),
            );
          }
        },
      );
    }
  }

  testWidgets('Cover di satu baris grid sejajar, sama besar, dan penuh', (
    tester,
  ) async {
    await bukaTabKoleksi(tester, daftarUkuranUji.first, 'Album');

    List<KartuGridKoleksi> semuaKartu = tester
        .widgetList<KartuGridKoleksi>(find.byType(KartuGridKoleksi))
        .toList();
    List<Rect> semuaCover = semuaKartu
        .map(
          (kartu) => tester.getRect(
            find.descendant(
              of: find.byWidget(kartu),
              matching: find.byType(CoverAlbum),
            ),
          ),
        )
        .toList();

    expect(semuaCover.length, greaterThanOrEqualTo(2));
    expect(semuaCover[0].top, closeTo(semuaCover[1].top, 0.5));
    expect(semuaCover[0].size, semuaCover[1].size);
    expect(
      semuaCover[0].width,
      closeTo(tester.getSize(find.byWidget(semuaKartu[0])).width, 0.5),
    );
  });
}
