import 'package:flutter_test/flutter_test.dart';

import 'package:capify/utils/saran_ejaan.dart';

void main() {
  test('Jarak ketik menghitung huruf yang beda', () {
    expect(hitungJarakKetik('weeknd', 'weeknd'), 0);
    expect(hitungJarakKetik('weekend', 'weeknd'), 1);
    expect(hitungJarakKetik('hindya', 'hindia'), 1);
    expect(hitungJarakKetik('', 'pop'), 3);
    expect(hitungJarakKetik('kitten', 'sitting'), 3);
  });

  test('Salah ketik satu kata disarankan ke frasa lengkapnya', () {
    List<String> kamus = ['The Weeknd', 'Starboy', 'Hindia'];

    expect(cariSaranEjaan('weekend', kamus), 'The Weeknd');
    expect(cariSaranEjaan('Hindya', kamus), 'Hindia');
    expect(cariSaranEjaan('starbo', kamus), 'Starboy');
  });

  test('Tidak ada saran kalau ketikannya terlalu jauh atau sudah benar', () {
    List<String> kamus = ['The Weeknd', 'Starboy'];

    expect(cariSaranEjaan('capybara', kamus), isNull);
    expect(cariSaranEjaan('starboy', kamus), isNull);
    expect(cariSaranEjaan('s', kamus), isNull);
    expect(cariSaranEjaan('weekend', []), isNull);
  });
}
