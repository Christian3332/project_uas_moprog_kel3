import 'package:flutter/foundation.dart';

import '../data/album_dummy.dart';
import '../data/playlist_dummy.dart';
import '../models/album.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _daftarPlaylistSaya = [];
  List<Album> _daftarAlbumTersimpan = [];
  final List<Lagu> _daftarLaguDisukai = [];
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

    await Future.delayed(const Duration(milliseconds: 800));

    if (_isProviderSudahDitutup) return;

    _daftarPlaylistSaya = List.of(daftarPlaylistDummy);
    _daftarAlbumTersimpan = List.of(daftarAlbumTersimpanDummy);
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
