import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capify/screens/explore_screen.dart';

void main() {
  testWidgets('Filter jenis hanya menampilkan kategori yang sesuai', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    expect(find.text('Pop'), findsOneWidget);

    await tester.tap(find.text('Suasana'));
    await tester.pump();

    expect(find.text('Pop'), findsNothing);
    expect(find.text('Lo-Fi'), findsOneWidget);
    expect(find.text('Santai'), findsOneWidget);
    expect(find.text('Kategori suasana'), findsOneWidget);
  });

  testWidgets('Filter digabung bisa kosong lalu direset', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));

    await tester.tap(find.text('Ada lagunya'));
    await tester.pump();
    expect(find.text('Hip-Hop'), findsNothing);
    expect(find.text('Pop'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Podcast'));
    await tester.pump();
    expect(
      find.text('Belum ada kategori podcast yang punya lagu'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tampilkan semua'));
    await tester.pump();
    expect(find.text('Hip-Hop'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
  });
}
