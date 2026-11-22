import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/screens/playlist_screen.dart';
import 'package:capify/services/koleksi_service.dart';

import 'pemutar_audio_palsu.dart';

void main() {
  late PemutarAudioPalsu pemutarPalsu;
  late AudioProvider audio;

  setUp(() {
    pemutarPalsu = PemutarAudioPalsu(
      lamaMemuat: const Duration(milliseconds: 10),
    );
    audio = AudioProvider(pemutarAudio: pemutarPalsu);
  });

  Future<void> bukaLayarKoleksi(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: audio),
          ChangeNotifierProvider(
            create: (context) => PlaylistProvider(
              koleksiService: const KoleksiService(
                lamaResponServer: Duration.zero,
              ),
            )..muatKoleksi(),
          ),
        ],
        child: const MaterialApp(home: PlaylistScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> tungguLaguSiap(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
  }

  testWidgets('Tombol putar memutar playlist dari lagu pertama', (
    tester,
  ) async {
    await bukaLayarKoleksi(tester);

    await tester.tap(find.byTooltip('Putar Teman Begadang'));
    await tungguLaguSiap(tester);

    expect(audio.namaAntrian, 'Teman Begadang');
    expect(audio.antrianLagu.length, 3);
    expect(audio.laguSekarang?.judul, 'One Call Away');
    expect(audio.isLaguSedangDiputar, isTrue);
    expect(find.byTooltip('Jeda Teman Begadang'), findsOneWidget);
    expect(find.text('Sedang diputar • 3 lagu'), findsOneWidget);
  });

  testWidgets('Tombol yang sama menjeda lalu melanjutkan playlist', (
    tester,
  ) async {
    await bukaLayarKoleksi(tester);
    await tester.tap(find.byTooltip('Putar Teman Begadang'));
    await tungguLaguSiap(tester);

    await tester.tap(find.byTooltip('Jeda Teman Begadang'));
    await tungguLaguSiap(tester);

    expect(audio.isLaguSedangDiputar, isFalse);
    expect(audio.namaAntrian, 'Teman Begadang');
    expect(find.byTooltip('Putar Teman Begadang'), findsOneWidget);

    await tester.tap(find.byTooltip('Putar Teman Begadang'));
    await tungguLaguSiap(tester);

    expect(audio.isLaguSedangDiputar, isTrue);
    expect(audio.laguSekarang?.judul, 'One Call Away');
  });

  testWidgets('Pindah ke playlist lain mengganti antrian lagu', (tester) async {
    await bukaLayarKoleksi(tester);
    await tester.tap(find.byTooltip('Putar Teman Begadang'));
    await tungguLaguSiap(tester);

    await tester.tap(find.byTooltip('Putar Semangat Pagi'));
    await tungguLaguSiap(tester);

    expect(audio.namaAntrian, 'Semangat Pagi');
    expect(audio.laguSekarang?.judul, 'Starboy');
    expect(find.byTooltip('Jeda Semangat Pagi'), findsOneWidget);
    expect(find.byTooltip('Putar Teman Begadang'), findsOneWidget);
  });

  testWidgets('Playlist kosong tidak diputar dan memberi tahu pengguna', (
    tester,
  ) async {
    await bukaLayarKoleksi(tester);
    String antrianSebelumnya = audio.namaAntrian;

    await tester.tap(find.byTooltip('Putar Playlist Baruku'));
    await tester.pump();

    expect(find.text('Playlist ini belum punya lagu'), findsOneWidget);
    expect(audio.namaAntrian, antrianSebelumnya);
    expect(audio.isLaguSedangDiputar, isFalse);
  });

  testWidgets('Pemutaran yang belum diizinkan tidak memulai antrian', (
    tester,
  ) async {
    await bukaLayarKoleksi(tester);
    audio.aturIzinPemutaran(false);
    int penolakanSebelumnya = audio.jumlahPutarDitolak;

    await tester.tap(find.byTooltip('Putar Teman Begadang'));
    await tungguLaguSiap(tester);

    expect(audio.jumlahPutarDitolak, penolakanSebelumnya + 1);
    expect(audio.namaAntrian, isNot('Teman Begadang'));
    expect(audio.isLaguSedangDiputar, isFalse);
  });
}
