import 'lagu.dart';

class RiwayatPutar {
  final Lagu lagu;
  final Duration jarakSejakDiputar;

  const RiwayatPutar({required this.lagu, required this.jarakSejakDiputar});

  String get teksWaktuDiputar {
    if (jarakSejakDiputar.inMinutes < 1) return 'Baru saja';
    if (jarakSejakDiputar.inMinutes < 60) {
      return '${jarakSejakDiputar.inMinutes} menit lalu';
    }
    if (jarakSejakDiputar.inHours < 24) {
      return '${jarakSejakDiputar.inHours} jam lalu';
    }
    if (jarakSejakDiputar.inDays < 2) return 'Kemarin';
    return '${jarakSejakDiputar.inDays} hari lalu';
  }
}
