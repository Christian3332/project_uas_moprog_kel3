class Album {
  final String judul;
  final String penyanyi;
  final String urlCover;
  final int jumlahLagu;

  const Album({
    required this.judul,
    required this.penyanyi,
    required this.urlCover,
    required this.jumlahLagu,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    String judulDariServer = json['title']?.toString().trim() ?? '';
    String penyanyiDariServer = json['artist']?.toString().trim() ?? '';
    int jumlahLaguDariServer = int.tryParse('${json['total_tracks']}') ?? 0;

    return Album(
      judul: judulDariServer.isEmpty ? 'Album Tanpa Judul' : judulDariServer,
      penyanyi: penyanyiDariServer.isEmpty
          ? 'Penyanyi tidak diketahui'
          : penyanyiDariServer,
      urlCover: json['cover_url']?.toString() ?? '',
      jumlahLagu: jumlahLaguDariServer < 0 ? 0 : jumlahLaguDariServer,
    );
  }
}
