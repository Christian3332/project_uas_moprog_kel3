import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/lagu.dart';
import 'package:capify/models/playlist.dart';
import 'package:capify/providers/playlist_provider.dart';
import 'package:capify/services/koleksi_service.dart';
import 'package:capify/services/supabase_koleksi_service.dart';

class KoleksiServiceBisaGagal extends KoleksiService {
  bool isTambahLaguGagal = false;

  KoleksiServiceBisaGagal()
    : super(lamaResponServer: const Duration(milliseconds: 20));

  @override
  Future<Playlist> tambahLaguKePlaylist({
    required Playlist playlist,
    required Lagu lagu,
  }) async {
    if (isTambahLaguGagal) {
      await Future.delayed(lamaResponServer);
      throw Exception('Server Capify sedang sibuk');
    }
    return super.tambahLaguKePlaylist(playlist: playlist, lagu: lagu);
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
    test('Menambah lagu membuat Playlist baru tanpa mengubah yang lama', () {
      Playlist playlistLama = const Playlist(
        id: 'pl-1',
        nama: 'Coba',
        deskripsi: 'Isi',
        daftarLagu: [],
      );

      Playlist playlistBaru = playlistLama.denganLaguTambahan(
        buatLaguContoh('Hype Boy', 'NewJeans'),
      );

      expect(playlistLama.daftarLagu, isEmpty);
      expect(playlistBaru.daftarLagu.length, 1);
      expect(playlistBaru.id, 'pl-1');
      expect(playlistBaru.nama, 'Coba');
    });

    test('Kunci lagu tidak peduli huruf besar kecil', () {
      expect(
        KoleksiService.buatKunciLagu(buatLaguContoh('DITTO', 'newjeans')),
        KoleksiService.buatKunciLagu(buatLaguContoh('Ditto', 'NewJeans')),
      );
    });

    test('Mock service menyimpan lagu dan menolak lagu ganda', () async {
      Playlist playlistTujuan = (await serviceCepat.ambilKoleksiPengguna())
          .daftarPlaylist
          .firstWhere((playlist) => playlist.id == idSemangatPagi);
      Lagu laguBaru = buatLaguContoh('Coffee', 'Beabadoobee');

      Playlist hasil = await serviceCepat.tambahLaguKePlaylist(
        playlist: playlistTujuan,
        lagu: laguBaru,
      );
      expect(hasil.daftarLagu.last.judul, 'Coffee');

      Playlist playlistDariServer = (await serviceCepat.ambilKoleksiPengguna())
          .daftarPlaylist
          .firstWhere((playlist) => playlist.id == idSemangatPagi);
      expect(playlistDariServer.daftarLagu.last.judul, 'Coffee');

      expect(
        () => serviceCepat.tambahLaguKePlaylist(
          playlist: playlistDariServer,
          lagu: buatLaguContoh('coffee', 'BEABADOOBEE'),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Playlist yang tidak ada di server ditolak', () async {
      expect(
        () => serviceCepat.tambahLaguKePlaylist(
          playlist: const Playlist(
            id: 'playlist-hantu',
            nama: 'Hantu',
            deskripsi: '',
            daftarLagu: [],
          ),
          lagu: buatLaguContoh('Get You', 'Daniel Caesar'),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PlaylistProvider menambah lagu', () {
    test('Lagu masuk ke playlist yang benar saja', () async {
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: serviceCepat);
      await koleksi.muatKoleksi();

      int jumlahAwal = koleksi.cariPlaylist(idTemanBegadang)!.daftarLagu.length;
      int jumlahPlaylistLain = koleksi
          .cariPlaylist(idSemangatPagi)!
          .daftarLagu
          .length;
      Lagu laguBaru = buatLaguContoh('Hype Boy', 'NewJeans');

      String? pesanGagal = await koleksi.tambahLaguKePlaylist(
        idPlaylist: idTemanBegadang,
        lagu: laguBaru,
      );

      expect(pesanGagal, isNull);
      expect(koleksi.isSedangMenambahLagu, isFalse);
      expect(
        koleksi.cariPlaylist(idTemanBegadang)!.daftarLagu.length,
        jumlahAwal + 1,
      );
      expect(koleksi.isLaguAdaDiPlaylist(idTemanBegadang, laguBaru), isTrue);
      expect(
        koleksi.cariPlaylist(idSemangatPagi)!.daftarLagu.length,
        jumlahPlaylistLain,
      );
    });

    test('Lagu yang sudah ada langsung ditolak tanpa ke server', () async {
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: serviceCepat);
      await koleksi.muatKoleksi();

      String? pesanGagal = await koleksi.tambahLaguKePlaylist(
        idPlaylist: idTemanBegadang,
        lagu: buatLaguContoh('ditto', 'newjeans'),
      );

      expect(pesanGagal, '"ditto" sudah ada di Teman Begadang');
    });

    test('Playlist yang tidak dikenal ditolak', () async {
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: serviceCepat);
      await koleksi.muatKoleksi();

      String? pesanGagal = await koleksi.tambahLaguKePlaylist(
        idPlaylist: 'playlist-hantu',
        lagu: buatLaguContoh('Starboy', 'The Weeknd'),
      );

      expect(pesanGagal, 'Playlist tidak ditemukan');
    });

    test('Tekan dua kali saat masih proses ditolak', () async {
      KoleksiServiceBisaGagal service = KoleksiServiceBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);
      await koleksi.muatKoleksi();

      Future<String?> prosesPertama = koleksi.tambahLaguKePlaylist(
        idPlaylist: idTemanBegadang,
        lagu: buatLaguContoh('Peaches', 'Justin Bieber'),
      );
      expect(koleksi.isSedangMenambahLagu, isTrue);

      String? pesanKedua = await koleksi.tambahLaguKePlaylist(
        idPlaylist: idTemanBegadang,
        lagu: buatLaguContoh('Attention', 'Charlie Puth'),
      );

      expect(pesanKedua, 'Lagu sebelumnya masih ditambahkan');
      expect(await prosesPertama, isNull);
    });

    test('Server gagal mengembalikan pesan dan isi playlist tetap', () async {
      KoleksiServiceBisaGagal service = KoleksiServiceBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);
      await koleksi.muatKoleksi();
      int jumlahAwal = koleksi.cariPlaylist(idSemangatPagi)!.daftarLagu.length;

      service.isTambahLaguGagal = true;
      String? pesanGagal = await koleksi.tambahLaguKePlaylist(
        idPlaylist: idSemangatPagi,
        lagu: buatLaguContoh('Fly Me to the Moon', 'Frank Sinatra'),
      );

      expect(pesanGagal, 'Server Capify sedang sibuk');
      expect(koleksi.isSedangMenambahLagu, isFalse);
      expect(
        koleksi.cariPlaylist(idSemangatPagi)!.daftarLagu.length,
        jumlahAwal,
      );
    });

    test('Provider ditutup saat menambah lagu tidak crash', () async {
      KoleksiServiceBisaGagal service = KoleksiServiceBisaGagal();
      PlaylistProvider koleksi = PlaylistProvider(koleksiService: service);
      await koleksi.muatKoleksi();

      Future<String?> proses = koleksi.tambahLaguKePlaylist(
        idPlaylist: idSemangatPagi,
        lagu: buatLaguContoh('Rumah ke Rumah', 'Hindia'),
      );
      koleksi.dispose();

      expect(await proses, isNull);
    });
  });

  group('Permintaan API Supabase', () {
    test('Kode error database diterjemahkan jadi pesan yang jelas', () {
      expect(
        SupabaseKoleksiService.pesanGagalTambahLagu('23505'),
        'Lagu ini sudah ada di playlist',
      );
      expect(
        SupabaseKoleksiService.pesanGagalTambahLagu('23503'),
        'Playlist ini belum tersimpan di server',
      );
      expect(
        SupabaseKoleksiService.pesanGagalTambahLagu('42501'),
        'Kamu tidak punya akses ke playlist ini',
      );
      expect(
        SupabaseKoleksiService.pesanGagalTambahLagu(null),
        'Lagu gagal ditambahkan, coba lagi sebentar',
      );
    });

    test('Tanpa koneksi Supabase permintaan gagal dengan pesan', () async {
      PlaylistProvider koleksi = PlaylistProvider(
        koleksiService: const SupabaseKoleksiService(),
      );
      await koleksi.muatKoleksi();

      String? pesanGagal = await koleksi.tambahLaguKePlaylist(
        idPlaylist: idTemanBegadang,
        lagu: buatLaguContoh('Get You', 'Daniel Caesar'),
      );

      expect(pesanGagal, 'Server Capify belum tersambung');
      expect(koleksi.isSedangMenambahLagu, isFalse);
    });
  });
}
