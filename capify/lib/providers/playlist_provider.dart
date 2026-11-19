import 'package:flutter/foundation.dart';

import '../models/album.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';
import '../services/koleksi_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final KoleksiService koleksiService;

  PlaylistProvider({this.koleksiService = const KoleksiService()});

  List<Playlist> _daftarPlaylistSaya = [];
  List<Album> _daftarAlbumTersimpan = [];
  List<Lagu> _daftarLaguDisukai = [];
  bool _isKoleksiSedangDimuat = false;
  bool _isKoleksiSudahPernahDimuat = false;
  bool _isProviderSudahDitutup = false;

  List<Playlist> get daftarPlaylistSaya =>
      List.unmodifiable(_daftarPlaylistSaya);
  List<Album> get daftarAlbumTersimpan =>
      List.unmodifiable(_daftarAlbumTersimpan);
  List<Lagu> get daftarLaguDisukai => List.unmodifiable(_daftarLaguDisukai);
  bool get isKoleksiSedangDimuat => _isKoleksiSedangDimuat;
  bool get isKoleksiSudahPernahDimuat => _isKoleksiSudahPernahDimuat;

  bool get isMasihMuatPertamaKali {
    return _isKoleksiSedangDimuat && !_isKoleksiSudahPernahDimuat;
  }

  void _kabariLayar() {
    if (_isProviderSudahDitutup) return;
    notifyListeners();
  }

  Future<void> muatKoleksi() async {
    if (_isKoleksiSedangDimuat) return;

    _isKoleksiSedangDimuat = true;
    _kabariLayar();

    Future<List<Playlist>> permintaanPlaylist = koleksiService
        .ambilPlaylistSaya();
    Future<List<Album>> permintaanAlbum = koleksiService.ambilAlbumTersimpan();
    Future<List<Lagu>> permintaanLaguDisukai = koleksiService
        .ambilLaguDisukai();

    List<Playlist> hasilPlaylist = await permintaanPlaylist;
    List<Album> hasilAlbum = await permintaanAlbum;
    List<Lagu> hasilLaguDisukai = await permintaanLaguDisukai;

    if (_isProviderSudahDitutup) return;

    _daftarPlaylistSaya = hasilPlaylist;
    _daftarAlbumTersimpan = hasilAlbum;
    _daftarLaguDisukai = hasilLaguDisukai;
    _isKoleksiSedangDimuat = false;
    _isKoleksiSudahPernahDimuat = true;
    _kabariLayar();
  }

  @override
  void dispose() {
    _isProviderSudahDitutup = true;
    super.dispose();
  }
}
