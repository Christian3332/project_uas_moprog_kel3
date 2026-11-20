import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/album.dart';
import '../models/koleksi_pengguna.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import 'koleksi_service.dart';

class SupabaseKoleksiService extends KoleksiService {
  static const String namaTabelPlaylist = 'playlists';
  static const String namaTabelLaguDisukai = 'liked_tracks';
  static const String namaTabelAlbumTersimpan = 'saved_albums';
  static const String kolomLagu =
      'id, title, artist, cover_url, audio_url, duration_ms';
  static const String kolomAlbum = 'id, title, artist, cover_url, total_tracks';

  static const KoleksiPengguna koleksiKosong = KoleksiPengguna(
    daftarPlaylist: [],
    daftarAlbumTersimpan: [],
    daftarLaguDisukai: [],
  );

  final Duration batasWaktuTunggu;

  const SupabaseKoleksiService({
    this.batasWaktuTunggu = const Duration(seconds: 10),
    super.lamaResponServer = Duration.zero,
  });

  @override
  Future<KoleksiPengguna> ambilKoleksiPengguna() async {
    try {
      SupabaseClient klienSupabase = Supabase.instance.client;
      User? penggunaAktif = klienSupabase.auth.currentUser;
      if (penggunaAktif == null) return koleksiKosong;

      Future<List<Map<String, dynamic>>> permintaanPlaylist = klienSupabase
          .from(namaTabelPlaylist)
          .select(
            'id, name, description, playlist_tracks(added_at, tracks($kolomLagu))',
          )
          .eq('user_id', penggunaAktif.id)
          .order('created_at', ascending: false)
          .order('added_at', referencedTable: 'playlist_tracks')
          .timeout(batasWaktuTunggu);

      Future<List<Map<String, dynamic>>> permintaanAlbum = klienSupabase
          .from(namaTabelAlbumTersimpan)
          .select('saved_at, albums($kolomAlbum)')
          .eq('user_id', penggunaAktif.id)
          .order('saved_at', ascending: false)
          .timeout(batasWaktuTunggu);

      Future<List<Map<String, dynamic>>> permintaanLaguDisukai = klienSupabase
          .from(namaTabelLaguDisukai)
          .select('liked_at, tracks($kolomLagu)')
          .eq('user_id', penggunaAktif.id)
          .order('liked_at', ascending: false)
          .timeout(batasWaktuTunggu);

      await Future.wait([
        permintaanPlaylist,
        permintaanAlbum,
        permintaanLaguDisukai,
      ]);

      List<Map<String, dynamic>> barisPlaylist = await permintaanPlaylist;

      return KoleksiPengguna(
        daftarPlaylist: barisPlaylist.map(ubahBarisKePlaylist).toList(),
        daftarAlbumTersimpan: ambilAlbumDariBaris(await permintaanAlbum),
        daftarLaguDisukai: ambilLaguDariBaris(await permintaanLaguDisukai),
      );
    } catch (_) {
      KoleksiPengguna koleksiCadangan = await super.ambilKoleksiPengguna();
      return koleksiCadangan.tandaiSebagaiCadangan();
    }
  }

  static Lagu? ubahDataTrackKeLagu(dynamic dataTrack) {
    if (dataTrack is! Map) return null;
    return Track.fromJson(Map<String, dynamic>.from(dataTrack)).keLagu();
  }

  static Playlist ubahBarisKePlaylist(Map<String, dynamic> baris) {
    List<Lagu> isiPlaylist = [];
    dynamic barisIsi = baris['playlist_tracks'];

    if (barisIsi is List) {
      for (dynamic isi in barisIsi) {
        Lagu? lagu = ubahDataTrackKeLagu(isi is Map ? isi['tracks'] : null);
        if (lagu != null) isiPlaylist.add(lagu);
      }
    }

    String namaDariServer = baris['name']?.toString().trim() ?? '';
    String deskripsiDariServer = baris['description']?.toString().trim() ?? '';

    return Playlist(
      id: baris['id']?.toString() ?? '',
      nama: namaDariServer.isEmpty ? 'Playlist Tanpa Nama' : namaDariServer,
      deskripsi: deskripsiDariServer.isEmpty
          ? 'Playlist buatanmu'
          : deskripsiDariServer,
      daftarLagu: isiPlaylist,
    );
  }

  static List<Lagu> ambilLaguDariBaris(List<Map<String, dynamic>> semuaBaris) {
    List<Lagu> hasilLagu = [];
    for (Map<String, dynamic> baris in semuaBaris) {
      Lagu? lagu = ubahDataTrackKeLagu(baris['tracks']);
      if (lagu != null) hasilLagu.add(lagu);
    }
    return hasilLagu;
  }

  static List<Album> ambilAlbumDariBaris(
    List<Map<String, dynamic>> semuaBaris,
  ) {
    List<Album> hasilAlbum = [];
    for (Map<String, dynamic> baris in semuaBaris) {
      dynamic dataAlbum = baris['albums'];
      if (dataAlbum is! Map) continue;
      hasilAlbum.add(Album.fromJson(Map<String, dynamic>.from(dataAlbum)));
    }
    return hasilAlbum;
  }
}
