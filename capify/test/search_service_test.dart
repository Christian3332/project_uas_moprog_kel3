import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/album.dart';
import 'package:capify/models/hasil_pencarian.dart';
import 'package:capify/services/search_service.dart';

SearchService serviceTanpaJeda() {
  return SearchService(lamaMenunggu: Duration.zero);
}

void main() {
  test('Mencari nama penyanyi mengembalikan track dan album', () async {
    HasilPencarian hasil = await serviceTanpaJeda().cari('weeknd');

    expect(hasil.daftarTrack.map((track) => track.judul), [
      'Die For You',
      'Starboy',
    ]);
    expect(hasil.daftarAlbum.map((album) => album.judul), ['Starboy']);
    expect(hasil.jumlahSemuaHasil, 3);
  });

  test('Judul yang persis sama tampil paling atas', () async {
    HasilPencarian hasil = await serviceTanpaJeda().cari('  STARBOY  ');

    expect(hasil.kataKunci, 'STARBOY');
    expect(hasil.daftarTrack.first.judul, 'Starboy');
    expect(hasil.daftarAlbum.first.jumlahLagu, 18);
  });

  test('Jenis pencarian membatasi isi hasil', () async {
    SearchService service = serviceTanpaJeda();

    HasilPencarian hanyaAlbum = await service.cari(
      'tulus',
      jenis: SearchService.jenisAlbum,
    );
    HasilPencarian hanyaTrack = await service.cari(
      'tulus',
      jenis: SearchService.jenisTrack,
    );

    expect(hanyaAlbum.daftarTrack, isEmpty);
    expect(hanyaAlbum.daftarAlbum.single.judul, 'Manusia');
    expect(hanyaTrack.daftarAlbum, isEmpty);
    expect(hanyaTrack.daftarTrack.single.judul, 'Cahaya');
  });

  test('Batas per jenis dipatuhi', () async {
    HasilPencarian hasil = await serviceTanpaJeda().cari('a', batasPerJenis: 2);

    expect(hasil.daftarTrack.length, lessThanOrEqualTo(2));
    expect(hasil.daftarAlbum.length, lessThanOrEqualTo(2));
  });

  test('Kata kunci kosong langsung kembali tanpa ke server', () async {
    SearchService service = SearchService(isServerSedangGangguan: true);

    HasilPencarian hasil = await service.cari('    ');

    expect(hasil.isKosong, isTrue);
  });

  test('Kata kunci yang tidak cocok menghasilkan hasil kosong', () async {
    HasilPencarian hasil = await serviceTanpaJeda().cari('zzzz capybara');

    expect(hasil.isKosong, isTrue);
    expect(hasil.kataKunci, 'zzzz capybara');
  });

  test('Error dilempar dengan pesan yang jelas', () async {
    SearchService service = serviceTanpaJeda()..isServerSedangGangguan = true;

    expect(service.cari('pop'), throwsA(isA<SearchException>()));
    expect(
      serviceTanpaJeda().cari('pop', jenis: 'podcast'),
      throwsA(isA<SearchException>()),
    );
    expect(serviceTanpaJeda().cari('a' * 61), throwsA(isA<SearchException>()));
  });

  test('Respons server yang rusak tidak bikin crash tanpa pesan', () {
    expect(
      () => SearchService.bacaResponsPencarian('{rusak'),
      throwsA(isA<SearchException>()),
    );
    expect(
      () => SearchService.bacaResponsPencarian('[1, 2]'),
      throwsA(isA<SearchException>()),
    );

    HasilPencarian hasilSetengahRusak = SearchService.bacaResponsPencarian(
      '{"query": "x", "tracks": "bukan list", "albums": [1, {"title": ""}]}',
    );
    expect(hasilSetengahRusak.daftarTrack, isEmpty);
    expect(hasilSetengahRusak.daftarAlbum.single.judul, 'Album Tanpa Judul');
  });

  test('Album dari JSON tetap aman walau jumlah lagunya aneh', () {
    Album album = Album.fromJson({
      'title': 'Tes',
      'artist': '   ',
      'total_tracks': -3,
    });

    expect(album.penyanyi, 'Penyanyi tidak diketahui');
    expect(album.jumlahLagu, 0);
    expect(album.urlCover, '');
  });
}
