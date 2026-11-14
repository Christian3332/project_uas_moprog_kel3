import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/lagu.dart';
import 'package:capify/screens/player_screen.dart';
import 'package:capify/widgets/cover_album.dart';

void main() {
  testWidgets('Player menampilkan pesan saat antrian kosong', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayerScreen(antrianLagu: [])),
    );

    expect(find.text('Belum ada lagu di antrian'), findsOneWidget);
    expect(find.byIcon(Icons.music_off_rounded), findsOneWidget);
    expect(find.text('SEDANG DIPUTAR DARI'), findsOneWidget);
  });

  testWidgets('Player memakai placeholder saat cover lagu kosong', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlayerScreen(
          namaAntrian: 'Playlist Santai',
          antrianLagu: [
            Lagu(
              judul: 'Lagu Tes',
              penyanyi: 'Penyanyi Tes',
              urlCover: '',
              durasi: Duration(minutes: 2),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Playlist Santai'), findsOneWidget);
    expect(find.text('Lagu Tes'), findsOneWidget);
    expect(find.byType(PlaceholderCover), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });
}
