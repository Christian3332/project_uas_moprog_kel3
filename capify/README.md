# Capify

Capify adalah aplikasi pemutar musik berbasis Flutter dengan tema gelap coklat-krem. Aplikasi ini dibuat untuk tugas UAS mata kuliah Mobile Programming oleh Kelompok 3.

## Fitur

- **Akun**: daftar, masuk, dan opsi "Ingat saya" supaya tidak perlu login ulang.
- **Onboarding & preferensi genre**: pengguna baru memilih genre favorit untuk mengisi beranda.
- **Beranda**: riwayat lagu yang terakhir diputar, racikan untukmu, dan temuan baru. Bisa ditarik ke bawah untuk menyegarkan, dan tetap menampilkan data tersimpan saat offline.
- **Jelajah**: daftar kategori musik beserta lagu di tiap kategori.
- **Cari**: pencarian lagu dan album dengan filter judul/penyanyi, riwayat pencarian, dan saran ejaan.
- **Koleksi**: playlist buatan sendiri, album tersimpan, dan lagu disukai.
- **Player**: putar/jeda, lagu berikutnya/sebelumnya, acak, ulangi, seekbar, tambah ke playlist, mini player di setiap tab, dan pemutaran di background lewat notifikasi.
- **Profil**: ubah nama tampilan, pengaturan pemutaran, dan keluar dari akun.

## Teknologi

| Kebutuhan | Package |
|---|---|
| State management | `provider` |
| Pemutar audio | `just_audio`, `just_audio_background`, `audio_session` |
| Backend | `supabase_flutter` |
| Penyimpanan lokal | `shared_preferences` |

## Cara Menjalankan

1. Pasang Flutter SDK (versi 3.x) dan siapkan HP Android atau emulator.
2. Masuk ke folder `capify`, lalu ambil semua dependensi:

   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi:

   ```bash
   flutter run
   ```

Kalau `lib/config/supabase_config.dart` masih kosong, Capify berjalan dengan data contoh, jadi semua layar tetap bisa dicoba tanpa server.

### Menyambungkan ke Supabase (opsional)

1. Buat project di [Supabase](https://supabase.com) dan aktifkan login dengan Email.
2. Buka SQL Editor, lalu jalankan file di folder `supabase/` sesuai urutan:
   `feed_beranda.sql`, `albums_pencarian.sql`, lalu `koleksi_pengguna.sql`.
3. Isi `url` dan `publishableKey` di `lib/config/supabase_config.dart` dengan Project URL dan Publishable key milik project tersebut.

### Menjalankan Test

```bash
flutter analyze
flutter test
```

## Struktur Folder

```
capify/
├── lib/
│   ├── config/     pengaturan koneksi Supabase
│   ├── data/       data contoh (lagu, album, playlist, kategori)
│   ├── models/     kelas data seperti Lagu, Album, Playlist, User
│   ├── providers/  state aplikasi: Auth, Audio, Home, Search, Playlist
│   ├── services/   akses data dari Supabase, data contoh, dan penyimpanan lokal
│   ├── screens/    halaman-halaman aplikasi
│   ├── widgets/    komponen tampilan yang dipakai ulang
│   ├── utils/      warna, format waktu, validasi, dan fungsi bantu lain
│   └── main.dart
├── supabase/       skrip SQL untuk tabel dan policy di Supabase
├── test/           unit test dan widget test
└── android/        konfigurasi aplikasi Android
```

## Anggota Kelompok 3

| Nama | NIM |
|---|---|
| Christian Benizi Susilo | 535250026 |
| Nicholas Jordan | 535250031 |
| Marcellino Febrian | 535250036 |
| Felix Lin | 535250044 |
| Fedri Marcello | 535250052 |
