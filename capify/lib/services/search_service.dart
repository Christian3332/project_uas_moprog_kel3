import 'dart:convert';

import '../models/hasil_pencarian.dart';
import 'feed_service.dart';
import 'track_api.dart';

class SearchException implements Exception {
  final String pesan;

  const SearchException(this.pesan);

  @override
  String toString() => pesan;
}

class SearchService {
  static const String jenisSemua = 'semua';
  static const String jenisTrack = 'track';
  static const String jenisAlbum = 'album';
  static const List<String> daftarJenisPencarian = [
    jenisSemua,
    jenisTrack,
    jenisAlbum,
  ];
  static const int batasPanjangKataKunci = 60;

  static const String responsAlbumDummy = '''
[
  {
    "id": "alb-001",
    "title": "Nine Track Mind",
    "artist": "Charlie Puth",
    "cover_url": "https://picsum.photos/seed/ninetrackmind/400",
    "total_tracks": 13
  },
  {
    "id": "alb-002",
    "title": "Starboy",
    "artist": "The Weeknd",
    "cover_url": "https://picsum.photos/seed/starboyalbum/400",
    "total_tracks": 18
  },
  {
    "id": "alb-003",
    "title": "OMG",
    "artist": "NewJeans",
    "cover_url": "https://picsum.photos/seed/newjeansomg/400",
    "total_tracks": 4
  },
  {
    "id": "alb-004",
    "title": "Case Study 01",
    "artist": "Daniel Caesar",
    "cover_url": "https://picsum.photos/seed/casestudy/400",
    "total_tracks": 10
  },
  {
    "id": "alb-005",
    "title": "Justice",
    "artist": "Justin Bieber",
    "cover_url": "https://picsum.photos/seed/justice/400",
    "total_tracks": 16
  },
  {
    "id": "alb-006",
    "title": "Menari Dengan Bayangan",
    "artist": "Hindia",
    "cover_url": "https://picsum.photos/seed/menaridenganbayangan/400",
    "total_tracks": 15
  },
  {
    "id": "alb-007",
    "title": "Manusia",
    "artist": "Tulus",
    "cover_url": "https://picsum.photos/seed/manusiatulus/400",
    "total_tracks": 10
  }
]
''';

  final Duration lamaMenunggu;
  final String? responsTrackKhusus;
  final String responsAlbumServer;
  bool isServerSedangGangguan;

  SearchService({
    this.lamaMenunggu = const Duration(milliseconds: 700),
    this.isServerSedangGangguan = false,
    this.responsTrackKhusus,
    this.responsAlbumServer = responsAlbumDummy,
  });

  static List<String> pecahKataKunci(String kataKunci) {
    return kataKunci
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((kata) => kata.isNotEmpty)
        .toList();
  }

  Future<HasilPencarian> cari(
    String kataKunci, {
    String jenis = jenisSemua,
    int batasPerJenis = 10,
  }) async {
    String kataRapi = kataKunci.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (kataRapi.isEmpty) {
      return const HasilPencarian(kataKunci: '');
    }
    if (kataRapi.length > batasPanjangKataKunci) {
      throw const SearchException(
        'Kata kuncinya kepanjangan, coba dipersingkat',
      );
    }
    if (!daftarJenisPencarian.contains(jenis)) {
      throw SearchException('Jenis pencarian "$jenis" tidak dikenal');
    }
    if (batasPerJenis <= 0) {
      return HasilPencarian(kataKunci: kataRapi);
    }

    String responsServer = await kirimPermintaanKeServer(
      kataRapi,
      jenis,
      batasPerJenis,
    );
    return bacaResponsPencarian(responsServer);
  }

  Future<String> kirimPermintaanKeServer(
    String kataKunci,
    String jenis,
    int batasPerJenis,
  ) async {
    await Future.delayed(lamaMenunggu);

    if (isServerSedangGangguan) {
      throw const SearchException(
        'Server pencarian sedang gangguan, coba lagi nanti',
      );
    }

    List<String> potonganKata = pecahKataKunci(kataKunci);

    List<Map<String, dynamic>> trackCocok = jenis == jenisAlbum
        ? []
        : saringDanUrutkan(
            ambilSemuaTrackMentah(),
            potonganKata,
            batasPerJenis,
          );
    List<Map<String, dynamic>> albumCocok = jenis == jenisTrack
        ? []
        : saringDanUrutkan(
            bacaDataMentah(responsAlbumServer),
            potonganKata,
            batasPerJenis,
          );

    return jsonEncode({
      'query': kataKunci,
      'tracks': trackCocok,
      'albums': albumCocok,
    });
  }

  List<Map<String, dynamic>> ambilSemuaTrackMentah() {
    if (responsTrackKhusus != null) {
      return bacaDataMentah(responsTrackKhusus!);
    }

    dynamic feedMentah = jsonDecode(FeedService.responsServerDummy);
    dynamic trackDiFeed = feedMentah is Map ? feedMentah['tracks'] : null;

    List<Map<String, dynamic>> semuaTrack = [
      ...bacaDataMentah(TrackApi.responsServerDummy),
      if (trackDiFeed is List) ...trackDiFeed.whereType<Map<String, dynamic>>(),
    ];

    Set<String> tandaYangSudahAda = {};
    return semuaTrack.where((track) {
      String tanda = '${track['title']}|${track['artist']}'.toLowerCase();
      return tandaYangSudahAda.add(tanda);
    }).toList();
  }

  List<Map<String, dynamic>> bacaDataMentah(String teksJson) {
    dynamic hasilDecode;
    try {
      hasilDecode = jsonDecode(teksJson);
    } on FormatException {
      return [];
    }
    if (hasilDecode is! List) return [];
    return hasilDecode.whereType<Map<String, dynamic>>().toList();
  }

  int _hitungSkorKecocokan(
    Map<String, dynamic> data,
    List<String> potonganKata,
  ) {
    String judul = data['title']?.toString().toLowerCase() ?? '';
    String penyanyi = data['artist']?.toString().toLowerCase() ?? '';
    String kataUtuh = potonganKata.join(' ');

    bool semuaKataKetemu = potonganKata.every(
      (kata) => judul.contains(kata) || penyanyi.contains(kata),
    );
    if (!semuaKataKetemu) return 0;

    if (judul == kataUtuh) return 4;
    if (judul.startsWith(kataUtuh)) return 3;
    if (judul.contains(kataUtuh)) return 2;
    return 1;
  }

  List<Map<String, dynamic>> saringDanUrutkan(
    List<Map<String, dynamic>> semuaData,
    List<String> potonganKata,
    int batas,
  ) {
    if (potonganKata.isEmpty) return [];

    List<MapEntry<Map<String, dynamic>, int>> dataBerskor = semuaData
        .map((data) => MapEntry(data, _hitungSkorKecocokan(data, potonganKata)))
        .where((dataDanSkor) => dataDanSkor.value > 0)
        .toList();

    dataBerskor.sort((entriA, entriB) {
      int bedaSkor = entriB.value - entriA.value;
      if (bedaSkor != 0) return bedaSkor;
      String judulA = entriA.key['title']?.toString().toLowerCase() ?? '';
      String judulB = entriB.key['title']?.toString().toLowerCase() ?? '';
      return judulA.compareTo(judulB);
    });

    return dataBerskor.take(batas).map((entri) => entri.key).toList();
  }

  static HasilPencarian bacaResponsPencarian(String teksJson) {
    dynamic hasilDecode;
    try {
      hasilDecode = jsonDecode(teksJson);
    } on FormatException {
      throw const SearchException('Hasil pencarian dari server rusak');
    }

    if (hasilDecode is! Map<String, dynamic>) {
      throw const SearchException(
        'Format hasil pencarian dari server tidak dikenali',
      );
    }

    return HasilPencarian.fromJson(hasilDecode);
  }
}
