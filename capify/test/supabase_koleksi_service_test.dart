import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/models/album.dart';
import 'package:capify/models/koleksi_pengguna.dart';
import 'package:capify/models/lagu.dart';
import 'package:capify/models/playlist.dart';
import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/screens/playlist_screen.dart';
import 'package:capify/services/koleksi_service.dart';
import 'package:capify/services/supabase_koleksi_service.dart';
import 'package:capify/widgets/komponen_beranda.dart';

import 'pemutar_audio_palsu.dart';

Widget bungkusLayarKoleksi(PlaylistProvider Function() buatKoleksi) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => AudioProvider(pemutarAudio: PemutarAudioPalsu()),
      ),
      ChangeNotifierProvider(create: (context) => buatKoleksi()),
    ],
    child: const MaterialApp(home: PlaylistScreen()),
  );
}

class KoleksiServiceBisaGagal extends KoleksiService {
  bool isHarusGagal = false;

  KoleksiServiceBisaGagal() : super(lamaResponServer: Duration.zero);

  @override
  Future<KoleksiPengguna> ambilKoleksiPengguna() async {
    if (isHarusGagal) throw Exception('Server Capify sedang sibuk');
    return super.ambilKoleksiPengguna();
  }
}

void main() {
  Map<String, dynamic> dataLaguEvaluasi = {
    'id': 'feed-004',
    'title': 'Evaluasi',
    'artist': 'Hindia',
    'cover_url': '',
    'audio_url': 'https://contoh.capify.id/evaluasi.mp3',
    'duration_ms': 227000,
  };

  group('Data koleksi dari server', () {
    test('Baris playlist diubah jadi Playlist beserta lagunya', () {
      Playlist playlist = SupabaseKoleksiService.ubahBarisKePlaylist({
        'id': 'pl-123',
        'name': '  Teman Skripsi  ',
        'description': 'Fokus nugas',
        'playlist_tracks': [
          {'added_at': '2026-11-20T10:00:00Z', 'tracks': dataLaguEvaluasi},
          {'added_at': '2026-11-20T10:05:00Z', 'tracks': null},
          'baris rusak',
        ],
      });

      expect(playlist.id, 'pl-123');
      expect(playlist.nama, 'Teman Skripsi');
      expect(playlist.deskripsi, 'Fokus nugas');
      expect(playlist.daftarLagu.length, 1);
      expect(playlist.daftarLagu.first.judul, 'Evaluasi');
      expect(playlist.daftarLagu.first.durasi, const Duration(seconds: 227));
      expect(
        playlist.daftarLagu.first.urlAudio,
        'https://contoh.capify.id/evaluasi.mp3',
      );
    });

    test('Playlist tanpa nama, deskripsi, dan isi tetap aman', () {
      Playlist playlist = SupabaseKoleksiService.ubahBarisKePlaylist({
        'id': 'pl-kosong',
        'name': '   ',
        'description': null,
      });

      expect(playlist.nama, 'Playlist Tanpa Nama');
      expect(playlist.deskripsi, 'Playlist buatanmu');
      expect(playlist.daftarLagu, isEmpty);
    });

    test('Lagu disukai dan album tersimpan yang datanya hilang dilewati', () {
      List<Lagu> laguDisukai = SupabaseKoleksiService.ambilLaguDariBaris([
        {'liked_at': '2026-11-20T10:00:00Z', 'tracks': dataLaguEvaluasi},
        {'liked_at': '2026-11-19T10:00:00Z', 'tracks': null},
      ]);
      List<Album> albumTersimpan = SupabaseKoleksiService.ambilAlbumDariBaris([
        {
          'saved_at': '2026-11-20T10:00:00Z',
          'albums': {
            'id': 'alb-006',
            'title': 'Menari Dengan Bayangan',
            'artist': 'Hindia',
            'cover_url': '',
            'total_tracks': 15,
          },
        },
        {'saved_at': '2026-11-19T10:00:00Z', 'albums': null},
      ]);

      expect(laguDisukai.length, 1);
      expect(laguDisukai.first.penyanyi, 'Hindia');
      expect(albumTersimpan.length, 1);
      expect(albumTersimpan.first.jumlahLagu, 15);
    });

    test('Supabase belum siap maka koleksi memakai data cadangan', () async {
      KoleksiPengguna koleksi = await const SupabaseKoleksiService()
          .ambilKoleksiPengguna();

      expect(koleksi.isDariCadangan, isTrue);
      expect(koleksi.daftarPlaylist.length, 3);
      expect(koleksi.daftarAlbumTersimpan.length, 6);
      expect(koleksi.daftarLaguDisukai.length, 4);
    });
  });

  group('PlaylistProvider memuat koleksi', () {
    test('Gagal muat tidak membuat loading macet dan data lama aman', () async {
      KoleksiServiceBisaGagal service = KoleksiServiceBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);

      await koleksi.muatKoleksi();
      expect(koleksi.daftarPlaylistSaya.length, 3);
      expect(koleksi.pesanGagal, isNull);

      service.isHarusGagal = true;
      await koleksi.muatKoleksi();

      expect(koleksi.isKoleksiSedangDimuat, isFalse);
      expect(koleksi.pesanGagal, 'Server Capify sedang sibuk');
      expect(koleksi.daftarPlaylistSaya.length, 3);

      service.isHarusGagal = false;
      await koleksi.muatKoleksi();
      expect(koleksi.pesanGagal, isNull);
    });
  });

  group('Layar koleksi', () {
    testWidgets('Gagal muat pertama kali menampilkan tombol coba lagi', (
      tester,
    ) async {
      KoleksiServiceBisaGagal service = KoleksiServiceBisaGagal()
        ..isHarusGagal = true;

      await tester.pumpWidget(
        bungkusLayarKoleksi(
          () => PlaylistProvider(koleksiService: service)..muatKoleksi(),
        ),
      );
      await tester.pump();

      expect(find.text('Server Capify sedang sibuk'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      service.isHarusGagal = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Coba lagi'), findsNothing);
      expect(find.byType(BarisPlaylistSaya), findsNWidgets(3));
    });

    testWidgets('Data cadangan menampilkan spanduk peringatan', (tester) async {
      await tester.pumpWidget(
        bungkusLayarKoleksi(
          () =>
              PlaylistProvider(koleksiService: const SupabaseKoleksiService())
                ..muatKoleksi(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SpandukDataCadangan), findsOneWidget);
      expect(find.byType(BarisPlaylistSaya), findsNWidgets(3));
    });

    testWidgets('Tarik untuk muat ulang yang gagal memunculkan snackbar', (
      tester,
    ) async {
      KoleksiServiceBisaGagal service = KoleksiServiceBisaGagal();

      await tester.pumpWidget(
        bungkusLayarKoleksi(
          () => PlaylistProvider(koleksiService: service)..muatKoleksi(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(BarisPlaylistSaya), findsNWidgets(3));

      service.isHarusGagal = true;
      await tester.fling(
        find.byType(BarisPlaylistSaya).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Server Capify sedang sibuk'), findsOneWidget);
      expect(find.byType(BarisPlaylistSaya), findsNWidgets(3));
    });
  });
}
