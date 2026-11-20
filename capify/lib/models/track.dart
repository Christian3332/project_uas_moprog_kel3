import 'lagu.dart';

class Track {
  final String id;
  final String judul;
  final String penyanyi;
  final String urlCover;
  final String urlAudio;
  final Duration durasi;

  const Track({
    required this.id,
    required this.judul,
    required this.penyanyi,
    required this.urlCover,
    required this.urlAudio,
    required this.durasi,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    String judulDariServer = json['title']?.toString().trim() ?? '';
    String penyanyiDariServer = json['artist']?.toString().trim() ?? '';
    num durasiDalamMilidetik = num.tryParse('${json['duration_ms']}') ?? 0;

    return Track(
      id: json['id']?.toString() ?? '',
      judul: judulDariServer.isEmpty ? 'Tanpa Judul' : judulDariServer,
      penyanyi: penyanyiDariServer.isEmpty
          ? 'Penyanyi tidak diketahui'
          : penyanyiDariServer,
      urlCover: json['cover_url']?.toString() ?? '',
      urlAudio: json['audio_url']?.toString() ?? '',
      durasi: Duration(
        milliseconds: durasiDalamMilidetik < 0
            ? 0
            : durasiDalamMilidetik.toInt(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': judul,
      'artist': penyanyi,
      'cover_url': urlCover,
      'audio_url': urlAudio,
      'duration_ms': durasi.inMilliseconds,
    };
  }

  bool get isBisaDiputar => urlAudio.trim().isNotEmpty;

  Lagu keLagu() {
    return Lagu(
      judul: judul,
      penyanyi: penyanyi,
      urlCover: urlCover,
      durasi: durasi,
      urlAudio: urlAudio,
    );
  }
}
