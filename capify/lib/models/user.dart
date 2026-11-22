class User {
  final String id;
  final String nama;
  final String email;
  final String urlFoto;
  final DateTime tanggalBergabung;

  const User({
    required this.id,
    required this.nama,
    required this.email,
    required this.urlFoto,
    required this.tanggalBergabung,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String namaDariServer = json['name']?.toString().trim() ?? '';
    DateTime? tanggalDariServer = DateTime.tryParse('${json['joined_at']}');

    return User(
      id: json['id']?.toString() ?? '',
      nama: namaDariServer.isEmpty ? 'Capy Lovers' : namaDariServer,
      email: json['email']?.toString().trim().toLowerCase() ?? '',
      urlFoto: json['photo_url']?.toString() ?? '',
      tanggalBergabung: tanggalDariServer ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nama,
      'email': email,
      'photo_url': urlFoto,
      'joined_at': tanggalBergabung.toIso8601String(),
    };
  }

  User salinDenganNamaBaru(String namaBaru) {
    return User(
      id: id,
      nama: namaBaru,
      email: email,
      urlFoto: urlFoto,
      tanggalBergabung: tanggalBergabung,
    );
  }

  bool get isPunyaFoto => urlFoto.trim().isNotEmpty;

  String get inisial {
    List<String> daftarKata = nama
        .split(RegExp(r'\s+'))
        .where((kata) => kata.isNotEmpty)
        .toList();

    if (daftarKata.isEmpty) return 'C';
    return daftarKata.take(2).map((kata) => kata[0]).join().toUpperCase();
  }
}
