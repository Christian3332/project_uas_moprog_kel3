import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/album.dart';
import 'package:capify/providers/playlist_provider.dart';

void main() {
  const Album albumA = Album(
    judul: 'Album A',
    penyanyi: 'Penyanyi A',
    urlCover: '',
    jumlahLagu: 10,
  );
  const Album albumB = Album(
    judul: 'Album B',
    penyanyi: 'Penyanyi B',
    urlCover: '',
    jumlahLagu: 8,
  );

  test('Album yang disimpan masuk ke koleksi lalu bisa dihapus lagi', () {
    PlaylistProvider koleksi = PlaylistProvider();

    koleksi.toggleAlbumTersimpan(albumA);
    expect(koleksi.isAlbumTersimpan(albumA), isTrue);
    expect(koleksi.isAlbumTersimpan(albumB), isFalse);
    expect(koleksi.daftarAlbumTersimpan.first.judul, 'Album A');

    koleksi.toggleAlbumTersimpan(albumA);
    expect(koleksi.isAlbumTersimpan(albumA), isFalse);
    expect(koleksi.daftarAlbumTersimpan, isEmpty);
  });
}
