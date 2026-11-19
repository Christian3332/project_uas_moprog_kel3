import 'album.dart';
import 'track.dart';

class HasilPencarian {
  final String kataKunci;
  final List<Track> daftarTrack;
  final List<Album> daftarAlbum;

  const HasilPencarian({
    required this.kataKunci,
    this.daftarTrack = const [],
    this.daftarAlbum = const [],
  });

  factory HasilPencarian.fromJson(Map<String, dynamic> json) {
    dynamic trackMentah = json['tracks'];
    dynamic albumMentah = json['albums'];

    return HasilPencarian(
      kataKunci: json['query']?.toString() ?? '',
      daftarTrack: trackMentah is List
          ? trackMentah
                .whereType<Map<String, dynamic>>()
                .map((dataTrack) => Track.fromJson(dataTrack))
                .toList()
          : [],
      daftarAlbum: albumMentah is List
          ? albumMentah
                .whereType<Map<String, dynamic>>()
                .map((dataAlbum) => Album.fromJson(dataAlbum))
                .toList()
          : [],
    );
  }

  bool get isKosong => daftarTrack.isEmpty && daftarAlbum.isEmpty;

  int get jumlahSemuaHasil => daftarTrack.length + daftarAlbum.length;
}
