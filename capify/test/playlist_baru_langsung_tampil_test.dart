import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capify/models/koleksi_pengguna.dart';
import 'package:capify/models/playlist.dart';
import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/screens/playlist_screen.dart';
import 'package:capify/services/koleksi_service.dart';

import 'pemutar_audio_palsu.dart';

class KoleksiServiceBanyakPlaylist extends KoleksiService {
  KoleksiServiceBanyakPlaylist() : super(lamaResponServer: Duration.zero);

  @override
  Future<KoleksiPengguna> ambilKoleksiPengguna() async {
    List<Playlist> banyakPlaylist = [];
    for (int nomor = 1; nomor <= 15; nomor++) {
      banyakPlaylist.add(
        Playlist(
          id: 'playlist-lama-$nomor',
          nama: 'Playlist Lama $nomor',
          deskripsi: 'Isi lama',
          daftarLagu: const [],
        ),
      );
    }

    return KoleksiPengguna(
      daftarPlaylist: banyakPlaylist,
      daftarAlbumTersimpan: const [],
      daftarLaguDisukai: const [],
    );
  }
}

void main() {
  Future<void> bukaLayarKoleksi(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) =>
                AudioProvider(pemutarAudio: PemutarAudioPalsu()),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                PlaylistProvider(koleksiService: KoleksiServiceBanyakPlaylist())
                  ..muatKoleksi(),
          ),
        ],
        child: const MaterialApp(home: PlaylistScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> buatPlaylistLewatForm(WidgetTester tester, String nama) async {
    await tester.tap(find.byTooltip('Buat playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, nama);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buat Playlist'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  BarisPlaylistSaya ambilBaris(WidgetTester tester, String namaPlaylist) {
    return tester.widget<BarisPlaylistSaya>(
      find.ancestor(
        of: find.text(namaPlaylist),
        matching: find.byType(BarisPlaylistSaya),
      ),
    );
  }

  testWidgets('Playlist baru langsung terlihat walau daftar sudah digulir', (
    tester,
  ) async {
    await bukaLayarKoleksi(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Playlist Lama 1'), findsNothing);

    await buatPlaylistLewatForm(tester, 'Lagu Hujan');

    expect(find.text('Lagu Hujan').hitTestable(), findsOneWidget);
    expect(find.text('Playlist Lama 1'), findsOneWidget);
    expect(ambilBaris(tester, 'Lagu Hujan').isBaruDibuat, isTrue);
    expect(ambilBaris(tester, 'Playlist Lama 1').isBaruDibuat, isFalse);
    expect(find.text('Playlist "Lagu Hujan" berhasil dibuat'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(ambilBaris(tester, 'Lagu Hujan').isBaruDibuat, isFalse);
  });

  testWidgets('Membuat playlist dari tab Album pindah ke tab Playlist', (
    tester,
  ) async {
    await bukaLayarKoleksi(tester);

    await tester.tap(find.text('Album'));
    await tester.pump();
    await buatPlaylistLewatForm(tester, 'Dari Tab Album');

    expect(find.text('Dari Tab Album').hitTestable(), findsOneWidget);
    expect(ambilBaris(tester, 'Dari Tab Album').isBaruDibuat, isTrue);

    BarisPlaylistSaya barisPertama = tester.widget<BarisPlaylistSaya>(
      find.byType(BarisPlaylistSaya).first,
    );
    expect(barisPertama.playlist.nama, 'Dari Tab Album');

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Batal membuat playlist tidak menyorot apa pun', (tester) async {
    await bukaLayarKoleksi(tester);

    await tester.tap(find.byTooltip('Buat playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    Iterable<BarisPlaylistSaya> semuaBaris = tester.widgetList(
      find.byType(BarisPlaylistSaya),
    );
    expect(semuaBaris.any((baris) => baris.isBaruDibuat), isFalse);
  });
}
