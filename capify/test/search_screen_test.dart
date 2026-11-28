import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/providers/search_provider.dart';
import 'package:capify/screens/detail_album_screen.dart';
import 'package:capify/screens/player_screen.dart';
import 'package:capify/screens/search_screen.dart';
import 'package:capify/services/search_service.dart';

import 'pemutar_audio_palsu.dart';

const String trackTanpaCover = '''
[
  {"id": "t1", "title": "Starboy", "artist": "The Weeknd", "duration_ms": 230000},
  {"id": "t2", "title": "Lights Up", "artist": "Harry Styles", "duration_ms": 172000}
]
''';

late SearchProvider pencarianTes;
late AudioProvider audioTes;

Future<void> bukaLayarCari(WidgetTester tester) async {
  pencarianTes = SearchProvider(
    searchService: SearchService(
      lamaMenunggu: Duration.zero,
      responsTrackKhusus: trackTanpaCover,
      responsAlbumServer: '[]',
    ),
    jedaSetelahMengetik: Duration.zero,
    kamusSaranEjaan: ['The Weeknd', 'Starboy', 'Harry Styles', 'Lights Up'],
  );
  audioTes = AudioProvider(pemutarAudio: PemutarAudioPalsu());

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pencarianTes),
        ChangeNotifierProvider.value(value: audioTes),
        ChangeNotifierProvider(create: (context) => PlaylistProvider()),
      ],
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

  testWidgets('Pencarian tanpa hasil menampilkan tips dan bisa dihapus', (
    tester,
  ) async {
    await bukaLayarCari(tester);

    await ketikLaluTunggu(tester, 'lights capybara');

    expect(find.textContaining('Tidak ada hasil untuk'), findsOneWidget);
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

  group('Putar lagu dari hasil pencarian', () {
    testWidgets('Ketuk lagu langsung memutar dengan antrian hasil pencarian', (
      tester,
    ) async {
      await bukaLayarCari(tester);
      await ketikLaluTunggu(tester, 'st');

      await tester.tap(find.text('Lights Up'));
      await tester.pump();
      expect(audioTes.isSedangMemuat, isTrue);
      await tester.pump(const Duration(milliseconds: 400));

      expect(audioTes.laguSekarang?.judul, 'Lights Up');
      expect(audioTes.indexLaguSekarang, 1);
      expect(audioTes.antrianLagu.map((lagu) => lagu.judul), [
        'Starboy',
        'Lights Up',
      ]);
      expect(audioTes.namaAntrian, 'Hasil cari "st"');
      expect(audioTes.isLaguSedangDiputar, isTrue);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      expect(pencarianTes.riwayatPencarian, ['st']);
    });

    testWidgets('Ketuk lagu yang sedang aktif membuka player layar penuh', (
      tester,
    ) async {
      await bukaLayarCari(tester);
      await ketikLaluTunggu(tester, 'starboy');
      await tester.tap(find.text('Starboy'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Starboy'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(audioTes.antrianLagu.length, 1);
    });

    testWidgets('Lagu yang dijeda ditandai dan dilanjutkan saat diketuk', (
      tester,
    ) async {
      await bukaLayarCari(tester);
      await ketikLaluTunggu(tester, 'starboy');
      await tester.tap(find.text('Starboy'));
      await tester.pump(const Duration(milliseconds: 400));

      audioTes.jeda();
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.text('Starboy'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(audioTes.isLaguSedangDiputar, isTrue);
    });

    testWidgets('Belum login maka lagu tidak diputar', (tester) async {
      await bukaLayarCari(tester);
      audioTes.aturIzinPemutaran(false);
      await ketikLaluTunggu(tester, 'starboy');

      await tester.tap(find.text('Starboy'));
      await tester.pump();

      expect(audioTes.laguSekarang, isNull);
      expect(audioTes.jumlahPutarDitolak, 1);
      expect(pencarianTes.riwayatPencarian, isEmpty);
    });

    testWidgets('Tombol lihat album tetap membuka detail album', (
      tester,
    ) async {
      await bukaLayarCari(tester);
      await ketikLaluTunggu(tester, 'starboy');

      await tester.tap(find.byTooltip('Lihat album'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(DetailAlbumScreen), findsOneWidget);
      expect(audioTes.laguSekarang, isNull);
    });
  });

  group('Tampilan kolom cari', () {
    BoxDecoration bacaHiasanKolom(WidgetTester tester) {
      AnimatedContainer kotakKolom = tester.widget(
        find.byKey(const ValueKey('kotak-kolom-cari')),
      );
      return kotakKolom.decoration! as BoxDecoration;
    }

    testWidgets('Kolom cari berbentuk pil dengan bayangan lembut', (
      tester,
    ) async {
      await bukaLayarCari(tester);

      BoxDecoration hiasan = bacaHiasanKolom(tester);
      expect(hiasan.borderRadius, BorderRadius.circular(lengkungKolomCari));
      expect(hiasan.boxShadow!.single.blurRadius, 10);

      TextField kolomCari = tester.widget(find.byType(TextField));
      OutlineInputBorder tepiDiam =
          kolomCari.decoration!.enabledBorder! as OutlineInputBorder;
      expect(tepiDiam.borderRadius, BorderRadius.circular(lengkungKolomCari));
      expect(tepiDiam.borderSide, BorderSide.none);
    });

    testWidgets('Bayangan menebal saat fokus lalu kembali saat dilepas', (
      tester,
    ) async {
      await bukaLayarCari(tester);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      BoxDecoration hiasanFokus = bacaHiasanKolom(tester);
      expect(hiasanFokus.boxShadow!.single.blurRadius, 18);
      expect(hiasanFokus.boxShadow!.single.offset, const Offset(0, 6));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(bacaHiasanKolom(tester).boxShadow!.single.blurRadius, 10);
    });

    testWidgets('Kolom tetap rapi di layar sempit dengan kata kunci panjang', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await bukaLayarCari(tester);
      await ketikLaluTunggu(
        tester,
        'kata kunci yang sangat panjang sekali untuk layar kecil',
      );

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Hapus kata kunci'), findsOneWidget);
    });
  });
}
