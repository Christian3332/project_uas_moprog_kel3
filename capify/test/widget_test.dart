import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/data/lagu_dummy.dart';
import 'package:capify/models/lagu.dart';
import 'package:capify/models/mode_ulang.dart';
import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/home_provider.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/providers/search_provider.dart';
import 'package:capify/screens/halaman_utama_screen.dart';
import 'package:capify/screens/player_screen.dart';
import 'package:capify/widgets/cover_album.dart';
import 'package:capify/widgets/kontrol_player.dart';
import 'package:capify/widgets/mini_player.dart';

import 'pemutar_audio_palsu.dart';

Widget bungkusDenganAudio(AudioProvider audio, Widget halaman) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => audio),
      ChangeNotifierProvider(create: (context) => HomeProvider()),
      ChangeNotifierProvider(create: (context) => SearchProvider()),
      ChangeNotifierProvider(create: (context) => PlaylistProvider()),
    ],
    child: MaterialApp(home: halaman),
  );
}

void main() {
  testWidgets('Player menampilkan pesan saat antrian kosong', (tester) async {
    await tester.pumpWidget(
      bungkusDenganAudio(AudioProvider(), const PlayerScreen()),
    );

    expect(find.text('Belum ada lagu di antrian'), findsOneWidget);
    expect(find.byIcon(Icons.music_off_rounded), findsOneWidget);
    expect(find.text('SEDANG DIPUTAR DARI'), findsOneWidget);
  });

  testWidgets('Player memakai placeholder saat cover lagu kosong', (
    tester,
  ) async {
    AudioProvider audio = AudioProvider()
      ..mulaiAntrian(
        const [
          Lagu(
            judul: 'Lagu Tes',
            penyanyi: 'Penyanyi Tes',
            urlCover: '',
            durasi: Duration(minutes: 2),
          ),
        ],
        namaAntrian: 'Playlist Santai',
        isLangsungDiputar: false,
      );

    await tester.pumpWidget(bungkusDenganAudio(audio, const PlayerScreen()));

    expect(find.text('Playlist Santai'), findsOneWidget);
    expect(find.text('Lagu Tes'), findsOneWidget);
    expect(find.byType(PlaceholderCover), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });

  testWidgets('Mini player dan player layar penuh selalu sinkron', (
    tester,
  ) async {
    AudioProvider audio = AudioProvider(pemutarAudio: PemutarAudioPalsu())
      ..mulaiAntrian(daftarLaguDummy, isLangsungDiputar: false);

    await tester.pumpWidget(
      bungkusDenganAudio(audio, const HalamanUtamaScreen()),
    );

    Finder teksDiMiniPlayer(String teks) {
      return find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.text(teks),
      );
    }

    expect(teksDiMiniPlayer('One Call Away'), findsOneWidget);

    await tester.tap(find.byTooltip('Putar'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byTooltip('Jeda'), findsOneWidget);

    await tester.tap(find.byTooltip('Lagu berikutnya'));
    await tester.pump();
    expect(teksDiMiniPlayer('Starboy'), findsOneWidget);

    await tester.tap(find.text('Koleksi'));
    await tester.pump();
    expect(teksDiMiniPlayer('Starboy'), findsOneWidget);

    await tester.tap(teksDiMiniPlayer('Starboy'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('SEDANG DIPUTAR DARI'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byTooltip('Putar'), findsOneWidget);
    expect(audio.isLaguSedangDiputar, isFalse);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Seekbar menampilkan waktu dengan format menit:detik', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeekbarPlayer(
            posisiSekarang: const Duration(seconds: 65),
            durasiLagu: const Duration(minutes: 3, seconds: 14),
            onGeser: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('1:05'), findsOneWidget);
    expect(find.text('3:14'), findsOneWidget);
  });

  testWidgets('Tombol kontrol memanggil aksi yang sesuai', (tester) async {
    List<String> aksiYangTerpanggil = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TombolKontrolPlayer(
            isLaguSedangDiputar: false,
            isSedangMemuat: false,
            isAcak: false,
            modeUlang: ModeUlang.satu,
            onTekanPlay: () => aksiYangTerpanggil.add('play'),
            onTekanPrevious: () => aksiYangTerpanggil.add('previous'),
            onTekanNext: () => aksiYangTerpanggil.add('next'),
            onTekanAcak: () => aksiYangTerpanggil.add('acak'),
            onTekanUlang: () => aksiYangTerpanggil.add('ulang'),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.tap(find.byTooltip('Lagu sebelumnya'));
    await tester.tap(find.byTooltip('Lagu berikutnya'));
    await tester.tap(find.byTooltip('Acak mati'));
    await tester.tap(find.byIcon(Icons.repeat_one_rounded));

    expect(aksiYangTerpanggil, ['play', 'previous', 'next', 'acak', 'ulang']);
  });

  testWidgets('Player menampilkan tombol coba lagi saat audio gagal dimuat', (
    tester,
  ) async {
    PemutarAudioPalsu pemutarPalsu = PemutarAudioPalsu(isHarusGagal: true);
    AudioProvider audio = AudioProvider(pemutarAudio: pemutarPalsu)
      ..mulaiAntrian(daftarLaguDummy, isLangsungDiputar: false);

    await tester.pumpWidget(bungkusDenganAudio(audio, const PlayerScreen()));

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(find.text('Menyiapkan lagu...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

    pemutarPalsu.isHarusGagal = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Coba lagi'), findsNothing);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });
}
