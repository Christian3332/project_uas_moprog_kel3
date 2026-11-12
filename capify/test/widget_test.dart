import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capify/screens/player_screen.dart';

void main() {
  testWidgets('Player menampilkan pesan saat antrian kosong', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayerScreen(antrianLagu: [])),
    );

    expect(find.text('Belum ada lagu di antrian'), findsOneWidget);
    expect(find.byIcon(Icons.music_off_rounded), findsOneWidget);
  });
}
