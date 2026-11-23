# Modul Authentication & Profil

Dikerjakan oleh **Anggota 2**: Modul 1 (Login & Register) dan Modul 15 (Profil & Pengaturan).

## Fitur

### Login
- Validasi format email dan password sebelum dikirim.
- Error muncul di bawah kolom yang salah, lalu hilang sendiri saat isinya diubah.
- Tombol **Masuk** terkunci 30 detik setelah 3 kali password salah.
- **Ingat saya**: sesi disimpan di perangkat, jadi saat aplikasi dibuka lagi pengguna langsung masuk ke Home.
- Kotak pesan merah untuk error umum: tidak ada internet, server lambat, email belum dikonfirmasi, terlalu sering mencoba.

### Register
- Nama hanya boleh berisi huruf (3–50 karakter).
- Indikator kekuatan password (Lemah / Sedang / Kuat). Minimal harus **Sedang**, tanpa spasi, dan tidak boleh memuat nama atau bagian depan email.
- Ulangi password dan centang Syarat & Ketentuan wajib diisi.
- Setelah berhasil, pengguna kembali ke Login dengan email sudah terisi.

### Profil & Pengaturan
- Dibuka dari **tombol avatar** (inisial nama) di pojok kanan atas Home.
- **Edit nama** langsung berubah di Profil, avatar, dan sapaan Home tanpa menunggu server. Kalau server gagal, nama kembali ke yang lama.
- Pengaturan: putar otomatis, kualitas streaming, notifikasi, mode hemat data (kualitas **Tinggi** terkunci saat hemat data aktif).
- **Keluar**: lagu dihentikan, sesi dihapus, lalu kembali ke Login.

### Akses Pemutar
- Tamu (belum login) bisa menjelajah, tapi **tidak bisa memutar lagu** atau membuka layar Player.
- Saat tamu mencoba memutar, muncul lembar **"Masuk dulu, yuk!"** dengan tombol ke halaman Login.

## Alur Aplikasi

```
Buka aplikasi
     ↓
CekSesiScreen (layar pembuka)
  ├─ ada sesi tersimpan → Home
  └─ tidak ada → Onboarding → Login ⇄ Register
                                ↓
                              Home → avatar → Profil → Keluar → Login
```

## Mode Mock dan Supabase

Aplikasi memilih layanan login secara otomatis saat dibuka:

| Kondisi | Layanan yang dipakai |
|---|---|
| URL & key di `lib/config/supabase_config.dart` **kosong** atau gagal terhubung | `AuthService` (mock, data di memori) |
| URL & key **terisi** dan Supabase siap | `SupabaseAuthService` |

### Akun demo (mode mock)
```
Email    : capy@capify.id
Password : capy123
```
Akun yang didaftarkan di mode mock **hilang** setiap aplikasi di-restart. Akun demo selalu ada.

### Cara mengaktifkan Supabase
1. Di dashboard Supabase buka **Project Settings → API Keys**, lalu salin **Project URL** dan **Publishable key**.
   Jangan pernah memakai *secret key* / *service_role*.
2. Isi kedua nilai itu di `lib/config/supabase_config.dart`.
3. Pastikan **Authentication → Sign In / Providers → Email** aktif.
4. Selama pengembangan, sebaiknya matikan **Confirm email**, karena batas kirim email bawaan Supabase hanya sekitar 2 per jam.
5. Setelah login sungguhan berhasil, akun demo di `AuthService` boleh dihapus.

## Struktur File

| File | Isi |
|---|---|
| `screens/login_screen.dart` | Halaman Masuk, validasi, kunci 30 detik |
| `screens/register_screen.dart` | Halaman Daftar, indikator password, persetujuan |
| `screens/profil_screen.dart` | Profil & Pengaturan, edit nama, keluar |
| `screens/cek_sesi_screen.dart` | Layar pembuka yang memulihkan sesi |
| `providers/auth_provider.dart` | State login: masuk, daftar, keluar, pulihkan sesi, ubah nama |
| `services/auth_service.dart` | Mock API dan daftar kode error |
| `services/supabase_auth_service.dart` | Implementasi Supabase dan penerjemah error Supabase |
| `services/sesi_lokal_service.dart` | Simpan/hapus sesi di perangkat (`shared_preferences`) |
| `models/user.dart` | Model `User` (tanpa password) |
| `utils/validasi_auth.dart` | Aturan validasi nama, email, password |
| `utils/pesan_error_auth.dart` | Semua teks pesan error di satu tempat |
| `config/supabase_config.dart` | URL & key Supabase |
| `widgets/komponen_auth.dart` | Komponen bersama: kolom input, tombol, kotak error, checkbox, dll. |
| `widgets/penjaga_pemutar.dart` | Menyamakan izin pemutar dengan status login dan menampilkan ajakan masuk |
| `widgets/tombol_avatar_profil.dart` | Avatar di Home menuju Profil/Login |
| `widgets/lembar_edit_nama.dart` | Form ubah nama |

### Perubahan di file anggota lain
| File | Perubahan |
|---|---|
| `main.dart` | `home: CekSesiScreen()`, `navigatorKey`, `builder: PenjagaPemutar` |
| `providers/audio_provider.dart` | `aturIzinPemutaran()` dan `mintaIzinPemutaran()` (izin bawaan aktif) |
| `screens/player_screen.dart` | Cek izin di `bukaLayarPenuh()` |
| `screens/home_screen.dart` | Nama sapaan dari `AuthProvider` dan tombol avatar |

## Skenario Uji

1. **Login gagal**: `orang@baru.com` / `123456` → error di bawah kolom email.
2. **Kunci 30 detik**: `capy@capify.id` dengan password salah 3 kali.
3. **Register**: coba password `abcdef` (lemah), lalu `Kopi123!` (lolos) → kembali ke Login dengan email terisi.
4. **Ingat saya**: login dengan centang → refresh/restart → langsung masuk Home.
5. **Tamu**: Onboarding → Mulai Sekarang → tekan ▶ → muncul "Masuk dulu, yuk!".
6. **Edit nama**: avatar → Edit Profil → ubah nama → sapaan Home ikut berubah.
7. **Keluar**: Profil → Keluar → kembali ke Login dan lagu berhenti.
