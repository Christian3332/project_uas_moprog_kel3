import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:capify/services/pengaturan_lokal_service.dart';

void main() {
  const PengaturanLokalService pengaturanLokal = PengaturanLokalService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Pengaturan yang belum pernah diubah memakai nilai awal', () async {
    bool isHematData = await pengaturanLokal.ambilSaklar(
      PengaturanLokalService.kunciHematData,
      nilaiAwal: false,
    );
    String kualitas = await pengaturanLokal.ambilKualitasStreaming(
      nilaiAwal: 'Normal',
    );

    expect(isHematData, isFalse);
    expect(kualitas, 'Normal');
  });

  test('Pengaturan yang disimpan terbaca lagi', () async {
    await pengaturanLokal.simpanSaklar(
      PengaturanLokalService.kunciHematData,
      true,
    );
    await pengaturanLokal.simpanKualitasStreaming('Rendah');

    bool isHematData = await pengaturanLokal.ambilSaklar(
      PengaturanLokalService.kunciHematData,
      nilaiAwal: false,
    );
    String kualitas = await pengaturanLokal.ambilKualitasStreaming(
      nilaiAwal: 'Normal',
    );

    expect(isHematData, isTrue);
    expect(kualitas, 'Rendah');
  });
}
