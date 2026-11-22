import '../providers/auth_provider.dart';

const String pesanTidakAdaInternet =
    'Tidak ada koneksi internet. Cek Wi-Fi atau data selulermu, lalu coba lagi.';
const String pesanServerTerlaluLama =
    'Server terlalu lama merespons. Tunggu sebentar, lalu coba lagi.';
const String pesanServerBermasalah =
    'Server Capify sedang bermasalah. Coba lagi beberapa saat lagi.';
const String pesanMasihDiproses =
    'Permintaan sebelumnya masih diproses, tunggu sebentar ya.';

String? pesanUmumGagalMasuk(KesalahanMasuk kesalahan) {
  return switch (kesalahan) {
    KesalahanMasuk.emailBelumDikonfirmasi =>
      'Email kamu belum dikonfirmasi. Buka kotak masuk email, klik link '
          'konfirmasi dari Capify, lalu masuk lagi.',
    KesalahanMasuk.terlaluSeringMencoba =>
      'Terlalu banyak percobaan masuk dari perangkat ini. '
          'Tunggu beberapa menit sebelum mencoba lagi.',
    KesalahanMasuk.tidakAdaInternet => pesanTidakAdaInternet,
    KesalahanMasuk.serverTerlaluLama => pesanServerTerlaluLama,
    KesalahanMasuk.masihDiproses => pesanMasihDiproses,
    KesalahanMasuk.gagalTerhubung => pesanServerBermasalah,
    KesalahanMasuk.emailBelumTerdaftar ||
    KesalahanMasuk.passwordSalah ||
    KesalahanMasuk.emailAtauPasswordSalah => null,
  };
}

String pesanGagalPerbaruiProfil(KesalahanProfil kesalahan) {
  return switch (kesalahan) {
    KesalahanProfil.belumMasuk => 'Masuk dulu untuk mengubah profilmu.',
    KesalahanProfil.masihDiproses =>
      'Perubahan sebelumnya masih disimpan, tunggu sebentar ya.',
    KesalahanProfil.sesiBerakhir =>
      'Sesi kamu sudah berakhir. Keluar lalu masuk lagi untuk mengubah profil.',
    KesalahanProfil.tidakAdaInternet => pesanTidakAdaInternet,
    KesalahanProfil.serverTerlaluLama => pesanServerTerlaluLama,
    KesalahanProfil.gagalTerhubung =>
      'Nama gagal disimpan karena server sedang bermasalah. Coba lagi nanti.',
  };
}

String? pesanUmumGagalDaftar(KesalahanDaftar kesalahan) {
  return switch (kesalahan) {
    KesalahanDaftar.pendaftaranDitutup =>
      'Pendaftaran akun baru sedang ditutup. Coba lagi nanti.',
    KesalahanDaftar.batasEmailTercapai =>
      'Server sedang membatasi pengiriman email konfirmasi. '
          'Tunggu sekitar satu jam, lalu daftar lagi.',
    KesalahanDaftar.terlaluSeringMencoba =>
      'Terlalu banyak percobaan daftar. Tunggu beberapa menit, lalu coba lagi.',
    KesalahanDaftar.tidakAdaInternet => pesanTidakAdaInternet,
    KesalahanDaftar.serverTerlaluLama => pesanServerTerlaluLama,
    KesalahanDaftar.masihDiproses => pesanMasihDiproses,
    KesalahanDaftar.gagalTerhubung => pesanServerBermasalah,
    KesalahanDaftar.emailSudahTerdaftar ||
    KesalahanDaftar.emailTidakBisaDipakai ||
    KesalahanDaftar.passwordTerlaluLemah => null,
  };
}
