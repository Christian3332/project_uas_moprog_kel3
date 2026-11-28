import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/lagu.dart';
import 'package:capify/providers/playlist_provider.dart';

void main() {
  const Lagu laguA = Lagu(
    judul: 'Lagu A',
    penyanyi: 'Penyanyi A',
    urlCover: '',
    durasi: Duration(minutes: 3),
  );
  const Lagu laguB = Lagu(
    judul: 'Lagu B',
    penyanyi: 'Penyanyi B',
    urlCover: '',
    durasi: Duration(minutes: 2),
  );

  test('Lagu yang disukai masuk ke daftar lalu bisa dibatalkan', () {
    PlaylistProvider koleksi = PlaylistProvider();

    koleksi.toggleLaguDisukai(laguA);
    expect(koleksi.isLaguDisukai(laguA), isTrue);
    expect(koleksi.isLaguDisukai(laguB), isFalse);
    expect(koleksi.daftarLaguDisukai.first.judul, 'Lagu A');

    koleksi.toggleLaguDisukai(laguA);
    expect(koleksi.isLaguDisukai(laguA), isFalse);
    expect(koleksi.daftarLaguDisukai, isEmpty);
  });
}
