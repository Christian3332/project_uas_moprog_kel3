import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/lagu.dart';
import 'package:capify/models/playlist.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/services/koleksi_service.dart';
import 'package:capify/services/supabase_koleksi_service.dart';

class KoleksiServiceHapusBisaGagal extends KoleksiService {
  bool isHapusGagal = false;

  KoleksiServiceHapusBisaGagal()
    : super(lamaResponServer: const Duration(milliseconds: 20));

  @override
  Future<Playlist> hapusLaguDariPlaylist({
    required Playlist playlist,
    required Lagu lagu,
  }) async {
    if (isHapusGagal) {
      await Future.delayed(lamaResponServer);
      throw Exception('Server Capify sedang sibuk');
    }
    return super.hapusLaguDariPlaylist(playlist: playlist, lagu: lagu);
  }
}

Lagu buatLaguContoh(String judul, String penyanyi) {
  return Lagu(
    judul: judul,
    penyanyi: penyanyi,
    urlCover: '',
    durasi: const Duration(minutes: 3),
  );
}

void main() {
  const String idTemanBegadang = 'playlist-teman-begadang';
  const String idSemangatPagi = 'playlist-semangat-pagi';
  const KoleksiService serviceCepat = KoleksiService(
    lamaResponServer: Duration.zero,
  );

  group('Model dan mock service', () {
    test('Menghapus lagu membuat Playlist baru dan urutan sisa tetap', () {
      Playlist playlistLama = Playlist(
        id: 'pl-1',
        nama: 'Coba',
        deskripsi: 'Isi',
        daftarLagu: [
          buatLaguContoh('Satu', 'A'),
          buatLaguContoh('Dua', 'B'),
          buatLaguContoh('Tiga', 'C'),
        ],
      );

      Playlist playlistBaru = playlistLama.denganLaguDihapus(
        buatLaguContoh('DUA', 'b'),
      );

      expect(playlistLama.daftarLagu.length, 3);
      expect(playlistBaru.daftarLagu.map((lagu) => lagu.judul).toList(), [
        'Satu',
        'Tiga',
      ]);
      expect(playlistBaru.id, 'pl-1');
    });

    test('Lagu dengan judul sama tapi penyanyi beda tidak ikut terhapus', () {
      Playlist playlistLama = Playlist(
        id: 'pl-2',
        nama: 'Cover',
        deskripsi: '',
        daftarLagu: [
          buatLaguContoh('Hallelujah', 'Leonard Cohen'),
          buatLaguContoh('Hallelujah', 'Jeff Buckley'),
        ],
      );

      Playlist playlistBaru = playlistLama.denganLaguDihapus(
        buatLaguContoh('Hallelujah', 'Jeff Buckley'),
      );

      expect(playlistBaru.daftarLagu.length, 1);
      expect(playlistBaru.daftarLagu.first.penyanyi, 'Leonard Cohen');
    });

    test('Mock service menghapus lagu dan menolak hapus dua kali', () async {
      Playlist playlistAsal = (await serviceCepat.ambilKoleksiPengguna())
          .daftarPlaylist
          .firstWhere((playlist) => playlist.id == idSemangatPagi);
      Lagu laguDihapus = buatLaguContoh('Peaches', 'Justin Bieber');

      Playlist hasil = await serviceCepat.hapusLaguDariPlaylist(
        playlist: playlistAsal,
        lagu: laguDihapus,
      );
      expect(hasil.daftarLagu.any((lagu) => lagu.judul == 'Peaches'), isFalse);

      expect(
        () => serviceCepat.hapusLaguDariPlaylist(
          playlist: hasil,
          lagu: laguDihapus,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Playlist yang tidak ada dan server sibuk sama-sama ditolak', () {
      Playlist playlistHantu = const Playlist(
        id: 'playlist-hantu',
        nama: 'Hantu',
        deskripsi: '',
        daftarLagu: [],
      );

      expect(
        () => serviceCepat.hapusLaguDariPlaylist(
          playlist: playlistHantu,
          lagu: buatLaguContoh('Get You', 'Daniel Caesar'),
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        () =>
            const KoleksiService(
              lamaResponServer: Duration.zero,
              isSimulasiGagal: true,
            ).hapusLaguDariPlaylist(
              playlist: playlistHantu,
              lagu: buatLaguContoh('Get You', 'Daniel Caesar'),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PlaylistProvider menghapus lagu', () {
    test('Lagu hilang dari playlist yang benar saja', () async {
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: serviceCepat);
      await koleksi.muatKoleksi();
      Lagu laguDihapus = buatLaguContoh('Evaluasi', 'Hindia');
      int jumlahAwal = koleksi.cariPlaylist(idTemanBegadang)!.daftarLagu.length;
      int jumlahPlaylistLain = koleksi
          .cariPlaylist(idSemangatPagi)!
          .daftarLagu
          .length;

      String? pesanGagal = await koleksi.hapusLaguDariPlaylist(
        idPlaylist: idTemanBegadang,
        lagu: laguDihapus,
      );

      expect(pesanGagal, isNull);
      expect(koleksi.isSedangMenghapusLagu, isFalse);
      expect(
        koleksi.cariPlaylist(idTemanBegadang)!.daftarLagu.length,
        jumlahAwal - 1,
      );
      expect(
        koleksi.isLaguAdaDiPlaylist(idTemanBegadang, laguDihapus),
        isFalse,
      );
      expect(
        koleksi.cariPlaylist(idSemangatPagi)!.daftarLagu.length,
        jumlahPlaylistLain,
      );
    });

    test('Lagu yang tidak ada di playlist langsung ditolak', () async {
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: serviceCepat);
      await koleksi.muatKoleksi();

      String? pesanGagal = await koleksi.hapusLaguDariPlaylist(
        idPlaylist: idTemanBegadang,
        lagu: buatLaguContoh('Hype Boy', 'NewJeans'),
      );

      expect(pesanGagal, '"Hype Boy" sudah tidak ada di Teman Begadang');
    });

    test('Playlist yang tidak dikenal ditolak', () async {
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: serviceCepat);
      await koleksi.muatKoleksi();

      String? pesanGagal = await koleksi.hapusLaguDariPlaylist(
        idPlaylist: 'playlist-hantu',
        lagu: buatLaguContoh('Ditto', 'NewJeans'),
      );

      expect(pesanGagal, 'Playlist tidak ditemukan');
    });

    test('Tekan hapus dua kali saat masih proses ditolak', () async {
      KoleksiServiceHapusBisaGagal service = KoleksiServiceHapusBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);
      await koleksi.muatKoleksi();

      Future<String?> prosesPertama = koleksi.hapusLaguDariPlaylist(
        idPlaylist: idTemanBegadang,
        lagu: buatLaguContoh('Ditto', 'NewJeans'),
      );
      expect(koleksi.isSedangMenghapusLagu, isTrue);

      String? pesanKedua = await koleksi.hapusLaguDariPlaylist(
        idPlaylist: idTemanBegadang,
        lagu: buatLaguContoh('One Call Away', 'Charlie Puth'),
      );

      expect(pesanKedua, 'Lagu sebelumnya masih dihapus');
      expect(await prosesPertama, isNull);
    });

    test('Server gagal mengembalikan pesan dan lagu tetap ada', () async {
      KoleksiServiceHapusBisaGagal service = KoleksiServiceHapusBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);
      await koleksi.muatKoleksi();
      Lagu laguDihapus = buatLaguContoh('Starboy', 'The Weeknd');

      service.isHapusGagal = true;
      String? pesanGagal = await koleksi.hapusLaguDariPlaylist(
        idPlaylist: idSemangatPagi,
        lagu: laguDihapus,
      );

      expect(pesanGagal, 'Server Capify sedang sibuk');
      expect(koleksi.isSedangMenghapusLagu, isFalse);
      expect(koleksi.isLaguAdaDiPlaylist(idSemangatPagi, laguDihapus), isTrue);
    });

    test('Lagu yang dihapus bisa ditambahkan lagi', () async {
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: serviceCepat);
      await koleksi.muatKoleksi();
      Lagu laguStarboy = buatLaguContoh('Starboy', 'The Weeknd');

      expect(
        await koleksi.hapusLaguDariPlaylist(
          idPlaylist: idSemangatPagi,
          lagu: laguStarboy,
        ),
        isNull,
      );
      expect(
        await koleksi.tambahLaguKePlaylist(
          idPlaylist: idSemangatPagi,
          lagu: laguStarboy,
        ),
        isNull,
      );
      expect(koleksi.isLaguAdaDiPlaylist(idSemangatPagi, laguStarboy), isTrue);
    });

    test('Provider ditutup saat menghapus lagu tidak crash', () async {
      KoleksiServiceHapusBisaGagal service = KoleksiServiceHapusBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);
      await koleksi.muatKoleksi();

      Future<String?> proses = koleksi.hapusLaguDariPlaylist(
        idPlaylist: idTemanBegadang,
        lagu: buatLaguContoh('One Call Away', 'Charlie Puth'),
      );
      koleksi.dispose();

      expect(await proses, isNull);
    });
  });

  group('Permintaan API Supabase', () {
    test('Kode error hapus diterjemahkan jadi pesan yang jelas', () {
      expect(
        SupabaseKoleksiService.pesanGagalHapusLagu('42501'),
        'Kamu tidak punya akses ke playlist ini',
      );
      expect(
        SupabaseKoleksiService.pesanGagalHapusLagu(null),
        'Lagu gagal dihapus, coba lagi sebentar',
      );
    });

    test(
      'Tanpa koneksi Supabase permintaan hapus gagal dengan pesan',
      () async {
        PlaylistProvider koleksi = PlaylistProvider(
          koleksiService: const SupabaseKoleksiService(),
        );
        await koleksi.muatKoleksi();

        String? pesanGagal = await koleksi.hapusLaguDariPlaylist(
          idPlaylist: idSemangatPagi,
          lagu: buatLaguContoh('Starboy', 'The Weeknd'),
        );

        expect(pesanGagal, 'Server Capify belum tersambung');
        expect(koleksi.isSedangMenghapusLagu, isFalse);
      },
    );
  });
}
