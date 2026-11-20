class Lagu {
  final String judul;
  final String penyanyi;
  final String urlCover;
  final Duration durasi;
  final String urlAudio;

  const Lagu({
    required this.judul,
    required this.penyanyi,
    required this.urlCover,
    required this.durasi,
    this.urlAudio = '',
  });
}
