import 'dart:convert';

import '../models/feed_beranda.dart';
import '../models/lagu.dart';

class FeedService {
  final Duration lamaResponServer;
  final bool isSimulasiGagal;
  final String responsServer;

  const FeedService({
    this.lamaResponServer = const Duration(milliseconds: 800),
    this.isSimulasiGagal = false,
    this.responsServer = responsServerDummy,
  });

  static const String responsServerDummy = '''
{
  "tracks": [
    {
      "id": "feed-001",
      "title": "One Call Away",
      "artist": "Charlie Puth",
      "cover_url": "https://picsum.photos/seed/onecallaway/500",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
      "duration_ms": 194000,
      "genre": "Pop"
    },
    {
      "id": "feed-002",
      "title": "Peaches",
      "artist": "Justin Bieber",
      "cover_url": "https://picsum.photos/seed/peachesbieber/400",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
      "duration_ms": 198000,
      "genre": "Pop"
    },
    {
      "id": "feed-003",
      "title": "Attention",
      "artist": "Charlie Puth",
      "cover_url": "https://picsum.photos/seed/attentionputh/400",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
      "duration_ms": 211000,
      "genre": "Pop"
    },
    {
      "id": "feed-004",
      "title": "Evaluasi",
      "artist": "Hindia",
      "cover_url": "https://picsum.photos/seed/evaluasihindia/400",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
      "duration_ms": 227000,
      "genre": "Indie"
    },
    {
      "id": "feed-005",
      "title": "Rumah ke Rumah",
      "artist": "Hindia",
      "cover_url": "https://picsum.photos/seed/rumahkerumah/400",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
      "duration_ms": 292000,
      "genre": "Indie"
    },
    {
      "id": "feed-006",
      "title": "Ditto",
      "artist": "NewJeans",
      "cover_url": "https://picsum.photos/seed/ditto/500",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3",
      "duration_ms": 185000,
      "genre": "K-Pop"
    },
    {
      "id": "feed-007",
      "title": "Hype Boy",
      "artist": "NewJeans",
      "cover_url": "https://picsum.photos/seed/hypeboy/400",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3",
      "duration_ms": 179000,
      "genre": "K-Pop"
    },
    {
      "id": "feed-008",
      "title": "Get You",
      "artist": "Daniel Caesar",
      "cover_url": "https://picsum.photos/seed/getyoucaesar/400",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3",
      "duration_ms": 278000,
      "genre": "R&B"
    },
    {
      "id": "feed-009",
      "title": "Starboy",
      "artist": "The Weeknd",
      "cover_url": "https://picsum.photos/seed/starboy/500",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3",
      "duration_ms": 230000,
      "genre": "R&B"
    },
    {
      "id": "feed-010",
      "title": "Fly Me to the Moon",
      "artist": "Frank Sinatra",
      "cover_url": "https://picsum.photos/seed/flymetothemoon/400",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3",
      "duration_ms": 148000,
      "genre": "Jazz"
    },
    {
      "id": "feed-011",
      "title": "Coffee",
      "artist": "Beabadoobee",
      "cover_url": "https://picsum.photos/seed/coffeebea/400",
      "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3",
      "duration_ms": 209000,
      "genre": "Lo-Fi"
    }
  ],
  "recently_played": [
    { "track_id": "feed-004", "played_minutes_ago": 4 },
    { "track_id": "feed-006", "played_minutes_ago": 38 },
    { "track_id": "feed-008", "played_minutes_ago": 180 },
    { "track_id": "feed-009", "played_minutes_ago": 540 },
    { "track_id": "feed-003", "played_minutes_ago": 1620 },
    { "track_id": "feed-002", "played_minutes_ago": 4320 }
  ]
}
''';

  Future<FeedBeranda> ambilFeedBeranda() async {
    await Future.delayed(lamaResponServer);

    if (isSimulasiGagal) {
      throw Exception('Server Capify sedang sibuk, feed belum bisa diambil');
    }

    return ubahJsonKeFeed(responsServer);
  }

  Future<void> catatRiwayatPutar(Lagu lagu) async {}

  static FeedBeranda ubahJsonKeFeed(String teksJson) {
    dynamic hasilDecode;
    try {
      hasilDecode = jsonDecode(teksJson);
    } on FormatException {
      throw Exception('Data feed dari server rusak');
    }

    if (hasilDecode is! Map<String, dynamic>) {
      throw Exception('Format data feed dari server tidak dikenali');
    }

    return FeedBeranda.fromJson(hasilDecode);
  }
}
