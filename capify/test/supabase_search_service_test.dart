import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/hasil_pencarian.dart';
import 'package:capify/services/supabase_search_service.dart';

void main() {
  test('Karakter yang merusak filter server dibuang', () {
    expect(
      SupabaseSearchService.bersihkanKataUntukFilter('star,boy)'),
      'starboy',
    );
    expect(SupabaseSearchService.bersihkanKataUntukFilter('100%*'), '100');
    expect(
      SupabaseSearchService.bersihkanKataUntukFilter("r&b-ku'"),
      "r&b-ku'",
    );
    expect(SupabaseSearchService.bersihkanKataUntukFilter('bébé'), 'bébé');
  });

  test('Kata terpanjang dipakai sebagai pancingan ke server', () {
    expect(
      SupabaseSearchService.pilihKataPancingan(['the', 'weeknd', 'star']),
      'weeknd',
    );
  });

  test('Tanpa koneksi Supabase hasil diambil dari data cadangan', () async {
    HasilPencarian hasil = await SupabaseSearchService().cari('hindia');

    expect(hasil.isDariCadangan, isTrue);
    expect(hasil.daftarTrack.map((track) => track.judul), [
      'Evaluasi',
      'Rumah ke Rumah',
    ]);
    expect(hasil.daftarAlbum.single.judul, 'Menari Dengan Bayangan');
  });

  test('Kata kunci yang isinya simbol saja tidak dikirim ke server', () async {
    HasilPencarian hasil = await SupabaseSearchService().cari(',,, %%');

    expect(hasil.isKosong, isTrue);
    expect(hasil.isDariCadangan, isFalse);
  });
}
