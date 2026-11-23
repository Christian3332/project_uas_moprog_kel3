class FormatWaktu {
  static String durasiLagu(Duration durasi) {
    String menit = durasi.inMinutes.toString();
    String detik = (durasi.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }
}
