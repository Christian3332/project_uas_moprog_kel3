import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'search_service.dart';

class SupabaseSearchService extends SearchService {
  static const String namaTabelLagu = 'tracks';
  static const String namaTabelAlbum = 'albums';
  static const int batasBarisDariServer = 50;

  final Duration batasWaktuTunggu;

  SupabaseSearchService({this.batasWaktuTunggu = const Duration(seconds: 10)})
    : super(lamaMenunggu: Duration.zero);

  static String bersihkanKataUntukFilter(String kata) {
    return kata.replaceAll(RegExp(r"[^\p{L}\p{N}\-&']", unicode: true), '');
  }

  static String pilihKataPancingan(List<String> potonganKata) {
    return potonganKata.reduce(
      (kataTerpanjang, kata) =>
          kata.length > kataTerpanjang.length ? kata : kataTerpanjang,
    );
  }

  @override
  Future<String> kirimPermintaanKeServer(
    String kataKunci,
    String jenis,
    int batasPerJenis,
  ) async {
    List<String> potonganKata = SearchService.pecahKataKunci(kataKunci)
        .map(bersihkanKataUntukFilter)
        .where((kata) => kata.isNotEmpty)
        .toList();

    if (potonganKata.isEmpty) {
      return jsonEncode({'query': kataKunci, 'tracks': [], 'albums': []});
    }

    try {
      SupabaseClient klienSupabase = Supabase.instance.client;
      String kataPancingan = pilihKataPancingan(potonganKata);
      String filterJudulAtauPenyanyi =
          'title.ilike.%$kataPancingan%,artist.ilike.%$kataPancingan%';

      List<Map<String, dynamic>> barisLagu = jenis == SearchService.jenisAlbum
          ? []
          : await klienSupabase
                .from(namaTabelLagu)
                .select('id, title, artist, cover_url, audio_url, duration_ms')
                .or(filterJudulAtauPenyanyi)
                .limit(batasBarisDariServer)
                .timeout(batasWaktuTunggu);

      List<Map<String, dynamic>> barisAlbum = jenis == SearchService.jenisTrack
          ? []
          : await _ambilAlbumDariServer(klienSupabase, filterJudulAtauPenyanyi);

      return jsonEncode({
        'query': kataKunci,
        'tracks': saringDanUrutkan(barisLagu, potonganKata, batasPerJenis),
        'albums': saringDanUrutkan(barisAlbum, potonganKata, batasPerJenis),
      });
    } catch (_) {
      String responsCadangan = await super.kirimPermintaanKeServer(
        kataKunci,
        jenis,
        batasPerJenis,
      );
      Map<String, dynamic> isiCadangan = jsonDecode(responsCadangan);
      isiCadangan['from_backup'] = true;
      return jsonEncode(isiCadangan);
    }
  }

  Future<List<Map<String, dynamic>>> _ambilAlbumDariServer(
    SupabaseClient klienSupabase,
    String filterJudulAtauPenyanyi,
  ) async {
    try {
      return await klienSupabase
          .from(namaTabelAlbum)
          .select('id, title, artist, cover_url, total_tracks')
          .or(filterJudulAtauPenyanyi)
          .limit(batasBarisDariServer)
          .timeout(batasWaktuTunggu);
    } catch (_) {
      return bacaDataMentah(responsAlbumServer);
    }
  }
}
