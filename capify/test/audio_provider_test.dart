import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/lagu.dart';
import 'package:capify/models/mode_ulang.dart';
import 'package:capify/providers/audio_provider.dart';

void main() {
  const List<Lagu> laguTes = [
    Lagu(
      judul: 'Lagu A',
      penyanyi: 'Penyanyi A',
      urlCover: '',
      durasi: Duration(minutes: 3),
    ),
    Lagu(
      judul: 'Lagu B',
      penyanyi: 'Penyanyi B',
      urlCover: '',
      durasi: Duration(minutes: 2),
    ),
  ];

  late AudioProvider audio;

  setUp(() {
    audio = AudioProvider();
    audio.mulaiAntrian(laguTes, isLangsungDiputar: false);
  });

  tearDown(() => audio.dispose());

  test('Antrian kosong tidak punya lagu sekarang', () {
    AudioProvider audioKosong = AudioProvider();
    expect(audioKosong.laguSekarang, isNull);
    expect(audioKosong.laguBerikutnya(), isFalse);
    audioKosong.dispose();
  });

  test('Index mulai yang kelewatan tetap aman', () {
    audio.mulaiAntrian(laguTes, indexMulai: 99, isLangsungDiputar: false);
    expect(audio.laguSekarang?.judul, 'Lagu B');
  });

  test('Next berhenti di lagu terakhir kalau mode ulang mati', () {
    expect(audio.laguBerikutnya(), isTrue);
    expect(audio.laguSekarang?.judul, 'Lagu B');
    expect(audio.laguBerikutnya(), isFalse);
    expect(audio.isLaguSedangDiputar, isFalse);
  });

  test('Next kembali ke lagu pertama kalau mode ulang semua', () {
    audio.gantiModeUlang();
    expect(audio.modeUlang, ModeUlang.semua);
    audio.laguBerikutnya();
    expect(audio.laguBerikutnya(), isTrue);
    expect(audio.laguSekarang?.judul, 'Lagu A');
  });

  test('Previous mengulang lagu kalau sudah lewat tiga detik', () {
    audio.laguBerikutnya();
    audio.geserKe(const Duration(seconds: 30));
    audio.laguSebelumnya();
    expect(audio.laguSekarang?.judul, 'Lagu B');
    expect(audio.posisiSekarang, Duration.zero);

    audio.laguSebelumnya();
    expect(audio.laguSekarang?.judul, 'Lagu A');
  });

  test('Geser seekbar tidak bisa melewati durasi lagu', () {
    audio.geserKe(const Duration(minutes: 10));
    expect(audio.posisiSekarang, const Duration(minutes: 3));
    audio.geserKe(const Duration(seconds: -5));
    expect(audio.posisiSekarang, Duration.zero);
  });

  test('Lagu disukai tetap tersimpan walau pindah lagu', () {
    audio.toggleSukaiLaguSekarang();
    audio.laguBerikutnya();
    expect(audio.isLaguSekarangDisukai, isFalse);
    audio.laguSebelumnya();
    expect(audio.isLaguSekarangDisukai, isTrue);
  });
}
