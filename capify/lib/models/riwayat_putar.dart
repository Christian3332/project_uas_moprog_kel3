import 'lagu.dart';

String ubahJarakWaktuJadiTeks(Duration jarakWaktu) {
  if (jarakWaktu.inMinutes < 1) return 'Baru saja';
  if (jarakWaktu.inMinutes < 60) return '${jarakWaktu.inMinutes} menit lalu';
  if (jarakWaktu.inHours < 24) return '${jarakWaktu.inHours} jam lalu';
  if (jarakWaktu.inDays < 2) return 'Kemarin';
  return '${jarakWaktu.inDays} hari lalu';
}

class RiwayatPutar {
  final Lagu lagu;
  final Duration jarakSejakDiputar;

  const RiwayatPutar({required this.lagu, required this.jarakSejakDiputar});

  String get teksWaktuDiputar => ubahJarakWaktuJadiTeks(jarakSejakDiputar);
}
