import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capify/screens/explore_screen.dart';

Future<void> bukaExplore(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 800));
}

Future<void> tungguFilterSelesai(WidgetTester tester) async {
  await tester.pump();
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('Filter jenis hanya menampilkan kategori yang sesuai', (
    tester,
  ) async {
    await bukaExplore(tester);
    expect(find.text('Pop'), findsOneWidget);

    await tester.tap(find.text('Suasana'));
    await tungguFilterSelesai(tester);

    expect(find.text('Pop'), findsNothing);
    expect(find.text('Lo-Fi'), findsOneWidget);
    expect(find.text('Santai'), findsOneWidget);
    expect(find.text('Kategori suasana'), findsOneWidget);
  });

  testWidgets('Filter digabung bisa kosong lalu direset', (tester) async {
    await bukaExplore(tester);

    await tester.tap(find.text('Ada lagunya'));
    await tungguFilterSelesai(tester);
    expect(find.text('Hip-Hop'), findsNothing);
    expect(find.text('Pop'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Podcast'));
    await tungguFilterSelesai(tester);
    expect(
      find.text('Belum ada kategori podcast yang punya lagu'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tampilkan semua'));
    await tungguFilterSelesai(tester);
    expect(find.text('Hip-Hop'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
  });

  testWidgets('Tap chip berkali-kali hanya memakai pilihan terakhir', (
    tester,
  ) async {
    await bukaExplore(tester);

    await tester.tap(find.text('Suasana'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Genre'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Pop'), findsOneWidget);
    expect(find.text('Lo-Fi'), findsNothing);
  });
}
