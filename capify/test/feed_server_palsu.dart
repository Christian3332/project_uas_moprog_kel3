import 'dart:async';

import 'package:capify/models/feed_beranda.dart';
import 'package:capify/services/feed_lokal_service.dart';
import 'package:capify/services/feed_service.dart';
import 'package:capify/services/supabase_feed_service.dart';

class FeedServerPalsu extends SupabaseFeedService {
  final List<Object?> urutanHasilServer;
  final String idPenggunaPalsu;
  int jumlahPanggilanServer = 0;

  FeedServerPalsu(
    this.urutanHasilServer, {
    this.idPenggunaPalsu = 'usr-uji',
    super.penyimpananLokal = const FeedLokalService(),
  });

  static Object galatOffline() {
    return TimeoutException('Server tidak menjawab');
  }

  static Object galatServer() {
    return Exception('Tabel tracks tidak ditemukan');
  }

  @override
  String idPenggunaAktif() => idPenggunaPalsu;

  @override
  Future<FeedBeranda> ambilDariServer() async {
    int urutan = jumlahPanggilanServer < urutanHasilServer.length
        ? jumlahPanggilanServer
        : urutanHasilServer.length - 1;
    jumlahPanggilanServer++;

    Object? hasil = urutanHasilServer[urutan];
    if (hasil != null) throw hasil;
    return FeedService.ubahJsonKeFeed(FeedService.responsServerDummy);
  }
}
