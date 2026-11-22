import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/models/playlist.dart';
import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/screens/playlist_screen.dart';
import 'package:capify/services/koleksi_service.dart';

import 'pemutar_audio_palsu.dart';

class KoleksiServiceSimpanBisaGagal extends KoleksiService {
  bool isSimpanGagal = false;
  bool isLemparErrorAneh = false;

  KoleksiServiceSimpanBisaGagal()
    : super(lamaResponServer: const Duration(milliseconds: 20));

  @override
  Future<Playlist> simpanPlaylistBaru({
    required String nama,
    required String deskripsi,
  }) async {
    if (isLemparErrorAneh) {
      await Future.delayed(lamaResponServer);
      throw StateError('koneksi putus di tengah jalan');
    }
    if (isSimpanGagal) {
      await Future.delayed(lamaResponServer);
      throw Exception('Server Capify sedang sibuk, playlist belum bisa dibuat');
    }
    return super.simpanPlaylistBaru(nama: nama, deskripsi: deskripsi);
  }
}

void main() {
  group('PlaylistProvider saat gagal membuat playlist', () {
    test('Gagal simpan mengembalikan pesan dan loading berhenti', () async {
      KoleksiServiceSimpanBisaGagal service = KoleksiServiceSimpanBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);
      await koleksi.muatKoleksi();
      int jumlahAwal = koleksi.daftarPlaylistSaya.length;

      service.isSimpanGagal = true;
      String? pesanGagal = await koleksi.buatPlaylistBaru(nama: 'Lagu Hujan');

      expect(
        pesanGagal,
        'Server Capify sedang sibuk, playlist belum bisa dibuat',
      );
      expect(koleksi.isSedangMembuatPlaylist, isFalse);
      expect(koleksi.daftarPlaylistSaya.length, jumlahAwal);
    });

    test('Setelah gagal, playlist yang sama bisa dicoba lagi', () async {
      KoleksiServiceSimpanBisaGagal service = KoleksiServiceSimpanBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);
      await koleksi.muatKoleksi();
      int jumlahAwal = koleksi.daftarPlaylistSaya.length;

      service.isSimpanGagal = true;
      await koleksi.buatPlaylistBaru(nama: 'Coba Lagi Dong');

      service.isSimpanGagal = false;
      String? pesanGagal = await koleksi.buatPlaylistBaru(
        nama: 'Coba Lagi Dong',
      );

      expect(pesanGagal, isNull);
      expect(koleksi.daftarPlaylistSaya.length, jumlahAwal + 1);
      expect(koleksi.daftarPlaylistSaya.first.nama, 'Coba Lagi Dong');
    });

    test('Error yang bukan Exception tetap diganti pesan yang ramah', () async {
      KoleksiServiceSimpanBisaGagal service = KoleksiServiceSimpanBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);
      await koleksi.muatKoleksi();

      service.isLemparErrorAneh = true;
      String? pesanGagal = await koleksi.buatPlaylistBaru(nama: 'Error Aneh');

      expect(pesanGagal, 'Playlist gagal dibuat, coba lagi sebentar');
      expect(koleksi.isSedangMembuatPlaylist, isFalse);
    });

    test('Mock service bisa disimulasikan gagal menyimpan', () async {
      expect(
        () => const KoleksiService(
          lamaResponServer: Duration.zero,
          isSimulasiGagal: true,
        ).simpanPlaylistBaru(nama: 'Gagal', deskripsi: ''),
        throwsA(isA<Exception>()),
      );
    });
  });

  testWidgets('Form tetap terbuka dan menampilkan pesan saat gagal', (
    tester,
  ) async {
    KoleksiServiceSimpanBisaGagal service = KoleksiServiceSimpanBisaGagal();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) =>
                AudioProvider(pemutarAudio: PemutarAudioPalsu()),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                PlaylistProvider(koleksiService: service)..muatKoleksi(),
          ),
        ],
        child: const MaterialApp(home: PlaylistScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    int jumlahAwal = tester.widgetList(find.byType(BarisPlaylistSaya)).length;

    service.isSimpanGagal = true;
    await tester.tap(find.byTooltip('Buat playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Gagal Dulu');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buat Playlist'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Buat Playlist Baru'), findsOneWidget);
    expect(
      find.text('Server Capify sedang sibuk, playlist belum bisa dibuat'),
      findsOneWidget,
    );
    ElevatedButton tombolSimpan = tester.widget(
      find.widgetWithText(ElevatedButton, 'Buat Playlist'),
    );
    expect(tombolSimpan.onPressed, isNotNull);

    service.isSimpanGagal = false;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buat Playlist'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Buat Playlist Baru'), findsNothing);
    expect(find.byType(BarisPlaylistSaya), findsNWidgets(jumlahAwal + 1));
  });
}
