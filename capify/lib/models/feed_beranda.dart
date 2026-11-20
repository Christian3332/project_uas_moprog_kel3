import 'lagu.dart';
import 'riwayat_putar.dart';
import 'track.dart';

class FeedBeranda {
  final List<RiwayatPutar> riwayatPutar;
  final Map<String, List<Lagu>> laguPerGenre;

  const FeedBeranda({required this.riwayatPutar, required this.laguPerGenre});

  bool get isKosong => riwayatPutar.isEmpty && laguPerGenre.isEmpty;

  int get jumlahLaguDiKatalog {
    int total = 0;
    for (List<Lagu> isiGenre in laguPerGenre.values) {
      total += isiGenre.length;
    }
    return total;
  }

  factory FeedBeranda.fromJson(Map<String, dynamic> json) {
    Map<String, Lagu> laguBerdasarkanId = {};
    Map<String, List<Lagu>> laguPerGenre = {};

    List<dynamic> daftarTrack = json['tracks'] is List ? json['tracks'] : [];
    for (dynamic dataTrack in daftarTrack) {
      if (dataTrack is! Map<String, dynamic>) continue;

      Track track = Track.fromJson(dataTrack);
      if (track.id.isEmpty || laguBerdasarkanId.containsKey(track.id)) {
        continue;
      }

      Lagu lagu = track.keLagu();
      laguBerdasarkanId[track.id] = lagu;

      String namaGenre = dataTrack['genre']?.toString().trim() ?? '';
      if (namaGenre.isNotEmpty) {
        laguPerGenre.putIfAbsent(namaGenre, () => []).add(lagu);
      }
    }

    List<RiwayatPutar> riwayatPutar = [];
    List<dynamic> daftarRiwayat = json['recently_played'] is List
        ? json['recently_played']
        : [];
    for (dynamic dataRiwayat in daftarRiwayat) {
      if (dataRiwayat is! Map<String, dynamic>) continue;

      Lagu? laguYangDiputar =
          laguBerdasarkanId[dataRiwayat['track_id']?.toString()];
      if (laguYangDiputar == null) continue;

      int menitYangLalu =
          int.tryParse('${dataRiwayat['played_minutes_ago']}') ?? 0;
      riwayatPutar.add(
        RiwayatPutar(
          lagu: laguYangDiputar,
          jarakSejakDiputar: Duration(
            minutes: menitYangLalu < 0 ? 0 : menitYangLalu,
          ),
        ),
      );
    }

    return FeedBeranda(riwayatPutar: riwayatPutar, laguPerGenre: laguPerGenre);
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> daftarTrack = [];
    Map<String, String> idBerdasarkanLagu = {};

    laguPerGenre.forEach((namaGenre, isiGenre) {
      for (Lagu lagu in isiGenre) {
        String idLagu = 'feed-${daftarTrack.length + 1}';
        idBerdasarkanLagu['${lagu.judul}|${lagu.penyanyi}'] = idLagu;
        daftarTrack.add({
          'id': idLagu,
          'title': lagu.judul,
          'artist': lagu.penyanyi,
          'cover_url': lagu.urlCover,
          'audio_url': lagu.urlAudio,
          'duration_ms': lagu.durasi.inMilliseconds,
          'genre': namaGenre,
        });
      }
    });

    List<Map<String, dynamic>> daftarRiwayat = [];
    for (RiwayatPutar riwayat in riwayatPutar) {
      String? idLagu =
          idBerdasarkanLagu['${riwayat.lagu.judul}|${riwayat.lagu.penyanyi}'];
      if (idLagu == null) continue;
      daftarRiwayat.add({
        'track_id': idLagu,
        'played_minutes_ago': riwayat.jarakSejakDiputar.inMinutes,
      });
    }

    return {'tracks': daftarTrack, 'recently_played': daftarRiwayat};
  }
}
