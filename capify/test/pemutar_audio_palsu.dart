import 'dart:async';

import 'package:just_audio/just_audio.dart';

class PemutarAudioPalsu implements AudioPlayer {
  bool isHarusGagal;
  final Duration durasiPalsu;
  final Duration lamaMemuat;

  PemutarAudioPalsu({
    this.isHarusGagal = false,
    this.durasiPalsu = const Duration(minutes: 5),
    this.lamaMemuat = const Duration(milliseconds: 300),
  });

  final StreamController<PlayerState> pengirimStatus =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> pengirimPosisi =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> pengirimDurasi =
      StreamController<Duration?>.broadcast();
  final StreamController<Duration> pengirimPosisiTerbuffer =
      StreamController<Duration>.broadcast();
  final StreamController<PlayerException> pengirimError =
      StreamController<PlayerException>.broadcast();

  bool isSedangMemutar = false;
  int jumlahDimuat = 0;
  String? urlTerakhirDimuat;
  Duration? posisiTerakhirDiseek;

  void selesaikanLagu() {
    pengirimStatus.add(PlayerState(true, ProcessingState.completed));
  }

  void mulaiBuffering() {
    pengirimStatus.add(PlayerState(isSedangMemutar, ProcessingState.buffering));
  }

  void selesaiBuffering() {
    pengirimStatus.add(PlayerState(isSedangMemutar, ProcessingState.ready));
  }

  void putuskanKoneksiDiTengahLagu() {
    isSedangMemutar = false;
    pengirimError.add(PlayerException(0, 'Koneksi terputus', null));
    pengirimStatus.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Stream<PlayerState> get playerStateStream => pengirimStatus.stream;

  @override
  Stream<Duration> get positionStream => pengirimPosisi.stream;

  @override
  Stream<Duration?> get durationStream => pengirimDurasi.stream;

  @override
  Stream<Duration> get bufferedPositionStream => pengirimPosisiTerbuffer.stream;

  @override
  Stream<PlayerException> get errorStream => pengirimError.stream;

  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    await Future.delayed(lamaMemuat);
    if (isHarusGagal) {
      throw PlayerException(0, 'Koneksi terputus', null);
    }
    jumlahDimuat++;
    urlTerakhirDimuat = url;
    pengirimStatus.add(PlayerState(isSedangMemutar, ProcessingState.ready));
    return durasiPalsu;
  }

  @override
  Future<void> play() async {
    isSedangMemutar = true;
    pengirimStatus.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    isSedangMemutar = false;
    pengirimStatus.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> stop() async {
    isSedangMemutar = false;
    pengirimStatus.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    posisiTerakhirDiseek = position;
    pengirimPosisi.add(position ?? Duration.zero);
  }

  @override
  Future<void> dispose() async {
    await pengirimStatus.close();
    await pengirimPosisi.close();
    await pengirimDurasi.close();
    await pengirimPosisiTerbuffer.close();
    await pengirimError.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
