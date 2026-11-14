final RegExp polaEmail = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

String? cekNama(String? isian) {
  String nama = (isian ?? '').trim();
  if (nama.isEmpty) return 'Nama belum diisi';
  if (nama.length < 3) return 'Nama minimal 3 huruf';
  return null;
}

String? cekEmail(String? isian) {
  String email = (isian ?? '').trim();
  if (email.isEmpty) return 'Email belum diisi';
  if (!polaEmail.hasMatch(email)) return 'Format email belum benar';
  return null;
}

String? cekPassword(String? isian) {
  String password = isian ?? '';
  if (password.isEmpty) return 'Password belum diisi';
  if (password.length < 6) return 'Password minimal 6 karakter';
  return null;
}

int hitungLevelPassword(String password) {
  if (password.isEmpty) return 0;

  int poinTambahan = 0;
  if (RegExp(r'\d').hasMatch(password)) poinTambahan++;
  if (RegExp(r'[A-Z]').hasMatch(password)) poinTambahan++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) poinTambahan++;

  if (password.length < 6 || poinTambahan == 0) return 1;
  if (password.length >= 8 && poinTambahan >= 2) return 3;
  return 2;
}
