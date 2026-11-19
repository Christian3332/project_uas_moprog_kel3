import 'dart:convert';

import '../models/track.dart';

class TrackApi {
  static const String responsServerDummy = '''
[
  {
    "id": "trk-001",
    "title": "One Call Away",
    "artist": "Charlie Puth",
    "cover_url": "https://picsum.photos/seed/onecallaway/500",
    "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    "duration_ms": 194000
  },
  {
    "id": "trk-002",
    "title": "Starboy",
    "artist": "The Weeknd",
    "cover_url": "https://picsum.photos/seed/starboy/500",
    "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    "duration_ms": 230000
  },
  {
    "id": "trk-003",
    "title": "Ditto",
    "artist": "NewJeans",
    "cover_url": "https://picsum.photos/seed/ditto/500",
    "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    "duration_ms": 185000
  },
  {
    "id": "trk-004",
    "title": "Die For You",
    "artist": "The Weeknd",
    "cover_url": "https://picsum.photos/seed/dieforyou/500",
    "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
    "duration_ms": 260000
  },
  {
    "id": "trk-005",
    "title": "Cahaya",
    "artist": "Tulus",
    "cover_url": "https://picsum.photos/seed/cahaya/500",
    "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
    "duration_ms": 211000
  }
]
''';

  static Future<List<Track>> ambilDaftarTrack({
    bool isSimulasiGagal = false,
    Duration lamaMenunggu = const Duration(milliseconds: 800),
  }) async {
    await Future.delayed(lamaMenunggu);

    if (isSimulasiGagal) {
      throw Exception('Gagal terhubung ke server, coba lagi nanti');
    }

    return ubahJsonKeDaftarTrack(responsServerDummy);
  }

  static List<Track> ubahJsonKeDaftarTrack(String teksJson) {
    dynamic hasilDecode;
    try {
      hasilDecode = jsonDecode(teksJson);
    } on FormatException {
      throw Exception('Data lagu dari server rusak');
    }

    if (hasilDecode is! List) {
      throw Exception('Format data lagu dari server tidak dikenali');
    }

    return hasilDecode
        .whereType<Map<String, dynamic>>()
        .map((dataTrack) => Track.fromJson(dataTrack))
        .toList();
  }
}
