import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/album.dart';
import '../models/koleksi_pengguna.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import 'koleksi_service.dart';

class SupabaseKoleksiService extends KoleksiService {
  static const String namaTabelLagu = 'tracks';
  static const String namaTabelPlaylist = 'playlists';
  static const String namaTabelIsiPlaylist = 'playlist_tracks';
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

  @override
  Future<Playlist> simpanPlaylistBaru({
    required String nama,
    required String deskripsi,
  }) async {
    SupabaseClient klienSupabase = _ambilKlienPenggunaAktif(
      'Masuk dulu supaya bisa membuat playlist',
    );

    Map<String, dynamic> barisPlaylist;
    try {
      barisPlaylist = await klienSupabase
          .from(namaTabelPlaylist)
          .insert({'name': nama, 'description': deskripsi})
          .select('id, name, description')
          .single()
          .timeout(batasWaktuTunggu);
    } on PostgrestException catch (error) {
      throw Exception(pesanGagalBuatPlaylist(error.code));
    } on TimeoutException {
      throw Exception('Server terlalu lama merespons, coba lagi ya');
    }

    return ubahBarisKePlaylist(barisPlaylist);
  }

  @override
  Future<Playlist> tambahLaguKePlaylist({
    required Playlist playlist,
    required Lagu lagu,
  }) async {
    SupabaseClient klienSupabase = _ambilKlienPenggunaAktif(
      'Masuk dulu supaya bisa menambah lagu ke playlist',
    );
    String idLagu = await _ambilIdLaguDiKatalog(klienSupabase, lagu);

    try {
      await klienSupabase
          .from(namaTabelIsiPlaylist)
          .insert({'playlist_id': playlist.id, 'track_id': idLagu})
          .timeout(batasWaktuTunggu);
    } on PostgrestException catch (error) {
      throw Exception(pesanGagalTambahLagu(error.code));
    } on TimeoutException {
      throw Exception('Server terlalu lama merespons, coba lagi ya');
    }

    return playlist.denganLaguTambahan(lagu);
  }

  @override
  Future<Playlist> hapusLaguDariPlaylist({
    required Playlist playlist,
    required Lagu lagu,
  }) async {
    SupabaseClient klienSupabase = _ambilKlienPenggunaAktif(
      'Masuk dulu supaya bisa menghapus lagu dari playlist',
    );
    String idLagu = await _ambilIdLaguDiKatalog(klienSupabase, lagu);

    List<Map<String, dynamic>> barisTerhapus;
    try {
      barisTerhapus = await klienSupabase
          .from(namaTabelIsiPlaylist)
          .delete()
          .eq('playlist_id', playlist.id)
          .eq('track_id', idLagu)
          .select('track_id')
          .timeout(batasWaktuTunggu);
    } on PostgrestException catch (error) {
      throw Exception(pesanGagalHapusLagu(error.code));
    } on TimeoutException {
      throw Exception('Server terlalu lama merespons, coba lagi ya');
    }

    if (barisTerhapus.isEmpty) {
      throw Exception('Lagu ini sudah tidak ada di playlist');
    }

    return playlist.denganLaguDihapus(lagu);
  }

  @override
  Future<void> simpanLaguDisukai(Lagu lagu) async {
    SupabaseClient klienSupabase = _ambilKlienPenggunaAktif(
      'Masuk dulu supaya bisa menyukai lagu',
    );
    String idLagu = await _ambilIdLaguDiKatalog(klienSupabase, lagu);

    try {
      await klienSupabase
          .from(namaTabelLaguDisukai)
          .insert({'track_id': idLagu})
          .timeout(batasWaktuTunggu);
    } on PostgrestException catch (error) {
      if (error.code == '23505') return;
      throw Exception(pesanGagalLaguDisukai(error.code));
    } on TimeoutException {
      throw Exception('Server terlalu lama merespons, coba lagi ya');
    }
  }

  @override
  Future<void> hapusLaguDisukai(Lagu lagu) async {
    SupabaseClient klienSupabase = _ambilKlienPenggunaAktif(
      'Masuk dulu supaya bisa menghapus lagu disukai',
    );
    String idLagu = await _ambilIdLaguDiKatalog(klienSupabase, lagu);

    try {
      await klienSupabase
          .from(namaTabelLaguDisukai)
          .delete()
          .eq('user_id', klienSupabase.auth.currentUser!.id)
          .eq('track_id', idLagu)
          .timeout(batasWaktuTunggu);
    } on PostgrestException catch (error) {
      throw Exception(pesanGagalLaguDisukai(error.code));
    } on TimeoutException {
      throw Exception('Server terlalu lama merespons, coba lagi ya');
    }
  }

  SupabaseClient _ambilKlienPenggunaAktif(String pesanBelumMasuk) {
    SupabaseClient klienSupabase;
    try {
      klienSupabase = Supabase.instance.client;
    } catch (_) {
      throw Exception('Server Capify belum tersambung');
    }

    if (klienSupabase.auth.currentUser == null) {
      throw Exception(pesanBelumMasuk);
    }
    return klienSupabase;
  }

  Future<String> _ambilIdLaguDiKatalog(
    SupabaseClient klienSupabase,
    Lagu lagu,
  ) async {
    Map<String, dynamic>? barisLagu;
    try {
      barisLagu = await klienSupabase
          .from(namaTabelLagu)
          .select('id')
          .eq('title', lagu.judul)
          .eq('artist', lagu.penyanyi)
          .limit(1)
          .maybeSingle()
          .timeout(batasWaktuTunggu);
    } catch (_) {
      throw Exception('Katalog lagu belum bisa dicek, coba lagi ya');
    }

    String idLagu = barisLagu?['id']?.toString() ?? '';
    if (idLagu.isEmpty) {
      throw Exception('Lagu "${lagu.judul}" belum ada di katalog Capify');
    }
    return idLagu;
  }

  static String pesanGagalBuatPlaylist(String? kodeError) {
    if (kodeError == '23514') return 'Nama playlist maksimal 40 karakter';
    if (kodeError == '42501') return 'Kamu belum punya akses membuat playlist';
    return 'Playlist gagal dibuat, coba lagi sebentar';
  }

  static String pesanGagalLaguDisukai(String? kodeError) {
    if (kodeError == '42501') return 'Kamu belum punya akses ke Lagu Disukai';
    return 'Lagu Disukai gagal diperbarui, coba lagi sebentar';
  }

  static String pesanGagalTambahLagu(String? kodeError) {
    if (kodeError == '23505') return 'Lagu ini sudah ada di playlist';
    if (kodeError == '23503') return 'Playlist ini belum tersimpan di server';
    if (kodeError == '42501') return 'Kamu tidak punya akses ke playlist ini';
    return 'Lagu gagal ditambahkan, coba lagi sebentar';
  }

  static String pesanGagalHapusLagu(String? kodeError) {
    if (kodeError == '42501') return 'Kamu tidak punya akses ke playlist ini';
    return 'Lagu gagal dihapus, coba lagi sebentar';
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
