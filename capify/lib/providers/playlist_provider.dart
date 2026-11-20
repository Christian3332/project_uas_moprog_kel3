import 'package:flutter/foundation.dart';

import '../models/album.dart';
import '../models/koleksi_pengguna.dart';
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
  bool _isSedangMembuatPlaylist = false;
  bool _isProviderSudahDitutup = false;
  bool _isMemakaiDataCadangan = false;
  String? _pesanGagal;

  final int batasPanjangNamaPlaylist = 40;

  List<Playlist> get daftarPlaylistSaya =>
      List.unmodifiable(_daftarPlaylistSaya);
  List<Album> get daftarAlbumTersimpan =>
      List.unmodifiable(_daftarAlbumTersimpan);
  List<Lagu> get daftarLaguDisukai => List.unmodifiable(_daftarLaguDisukai);
  bool get isKoleksiSedangDimuat => _isKoleksiSedangDimuat;
  bool get isKoleksiSudahPernahDimuat => _isKoleksiSudahPernahDimuat;
  bool get isSedangMembuatPlaylist => _isSedangMembuatPlaylist;
  bool get isMemakaiDataCadangan => _isMemakaiDataCadangan;
  String? get pesanGagal => _pesanGagal;

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
    _pesanGagal = null;
    _kabariLayar();

    try {
      KoleksiPengguna koleksiDariServer = await koleksiService
          .ambilKoleksiPengguna();
      if (_isProviderSudahDitutup) return;

      _daftarPlaylistSaya = List.of(koleksiDariServer.daftarPlaylist);
      _daftarAlbumTersimpan = List.of(koleksiDariServer.daftarAlbumTersimpan);
      _daftarLaguDisukai = List.of(koleksiDariServer.daftarLaguDisukai);
      _isMemakaiDataCadangan = koleksiDariServer.isDariCadangan;
      _isKoleksiSudahPernahDimuat = true;
    } catch (error) {
      _pesanGagal = _rapikanPesanGagal(error);
    }

    _isKoleksiSedangDimuat = false;
    _kabariLayar();
  }

  String _rapikanPesanGagal(Object error) {
    String pesanAsli = error.toString().replaceFirst('Exception: ', '').trim();
    if (pesanAsli.isEmpty) return 'Koleksi gagal dimuat, coba lagi sebentar ya';
    return pesanAsli;
  }

  String? cekNamaPlaylistBaru(String? namaYangDiketik) {
    String namaRapi = (namaYangDiketik ?? '').trim();

    if (namaRapi.isEmpty) return 'Nama playlist belum diisi';
    if (namaRapi.length > batasPanjangNamaPlaylist) {
      return 'Nama playlist maksimal $batasPanjangNamaPlaylist karakter';
    }

    bool isNamaSudahDipakai = _daftarPlaylistSaya.any(
      (playlist) => playlist.nama.toLowerCase() == namaRapi.toLowerCase(),
    );
    if (isNamaSudahDipakai) return 'Kamu sudah punya playlist "$namaRapi"';

    return null;
  }

  Future<String?> buatPlaylistBaru({
    required String nama,
    String deskripsi = '',
  }) async {
    if (_isSedangMembuatPlaylist) return 'Playlist sebelumnya masih dibuat';
    if (_isKoleksiSedangDimuat) return 'Tunggu koleksi selesai dimuat dulu';

    String? pesanGagal = cekNamaPlaylistBaru(nama);
    if (pesanGagal != null) return pesanGagal;

    String deskripsiRapi = deskripsi.trim();

    _isSedangMembuatPlaylist = true;
    _kabariLayar();

    Playlist playlistBaru = await koleksiService.simpanPlaylistBaru(
      nama: nama.trim(),
      deskripsi: deskripsiRapi.isEmpty ? 'Playlist buatanmu' : deskripsiRapi,
    );

    if (_isProviderSudahDitutup) return null;

    _daftarPlaylistSaya = [playlistBaru, ..._daftarPlaylistSaya];
    _isSedangMembuatPlaylist = false;
    _kabariLayar();
    return null;
  }

  @override
  void dispose() {
    _isProviderSudahDitutup = true;
    super.dispose();
  }
}
