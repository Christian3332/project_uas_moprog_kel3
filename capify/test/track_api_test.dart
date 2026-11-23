import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/track.dart';
import 'package:capify/services/track_api.dart';

void main() {
  test('Track dibaca lengkap dari JSON server', () {
    Track track = Track.fromJson({
      'id': 'trk-001',
      'title': 'One Call Away',
      'artist': 'Charlie Puth',
      'cover_url': 'https://contoh.com/cover.jpg',
      'audio_url': 'https://contoh.com/lagu.mp3',
      'duration_ms': 194000,
    });

    expect(track.id, 'trk-001');
    expect(track.judul, 'One Call Away');
    expect(track.durasi, const Duration(minutes: 3, seconds: 14));
    expect(track.urlAudio, 'https://contoh.com/lagu.mp3');
  });

  test('Track tetap aman walau data dari server tidak lengkap', () {
    Track track = Track.fromJson({
      'id': 7,
      'title': '   ',
      'duration_ms': 'bukan angka',
    });

    expect(track.id, '7');
    expect(track.judul, 'Tanpa Judul');
    expect(track.penyanyi, 'Penyanyi tidak diketahui');
    expect(track.durasi, Duration.zero);
    expect(track.urlAudio, isEmpty);
  });

  test('Track bisa diubah jadi Lagu dan kembali jadi JSON', () {
    Track track = Track.fromJson({
      'id': 'trk-002',
      'title': 'Starboy',
      'artist': 'The Weeknd',
      'duration_ms': '230000',
    });

    expect(track.keLagu().judul, 'Starboy');
    expect(track.keLagu().durasi, const Duration(minutes: 3, seconds: 50));
    expect(track.toJson()['duration_ms'], 230000);
  });

  test('Mock API mengembalikan daftar track', () async {
    List<Track> daftarTrack = await TrackApi.ambilDaftarTrack(
      lamaMenunggu: Duration.zero,
    );

    expect(daftarTrack, isNotEmpty);
    expect(daftarTrack.first.judul, 'One Call Away');
    expect(daftarTrack.every((track) => track.id.isNotEmpty), isTrue);
  });

  test('Mock API melempar error saat simulasi gagal', () async {
    expect(
      TrackApi.ambilDaftarTrack(
        isSimulasiGagal: true,
        lamaMenunggu: Duration.zero,
      ),
      throwsException,
    );
  });

  test('JSON rusak tidak bikin aplikasi crash tanpa pesan', () {
    expect(() => TrackApi.ubahJsonKeDaftarTrack('{rusak'), throwsException);
    expect(() => TrackApi.ubahJsonKeDaftarTrack('{"a": 1}'), throwsException);
    expect(TrackApi.ubahJsonKeDaftarTrack('[1, "teks", {}]').length, 1);
  });
}
