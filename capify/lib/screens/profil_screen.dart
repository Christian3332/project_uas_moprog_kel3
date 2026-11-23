import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/playlist_dummy.dart';
import '../data/riwayat_putar_dummy.dart';
import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import '../utils/pesan_error_auth.dart';
import '../utils/warna_capify.dart';
import '../widgets/komponen_auth.dart';
import '../widgets/lembar_edit_nama.dart';
import 'login_screen.dart';

const List<String> pilihanKualitasStreaming = ['Rendah', 'Normal', 'Tinggi'];

const Map<String, String> keteranganKualitas = {
  'Rendah': 'Sekitar 24 kbps, paling irit kuota',
  'Normal': 'Sekitar 96 kbps, seimbang',
  'Tinggi': 'Sekitar 160 kbps, suara paling jernih',
};

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool isPutarOtomatis = true;
  bool isNotifikasiAktif = true;
  bool isHematData = false;
  String kualitasStreaming = 'Normal';
  bool isSedangKeluar = false;

  int get jumlahLaguDisimpan {
    return daftarPlaylistDummy.fold<int>(
      0,
      (totalSementara, playlist) => totalSementara + playlist.daftarLagu.length,
    );
  }

  Future<void> bukaEditNama() async {
    AuthProvider authProvider = context.read<AuthProvider>();
    if (!authProvider.isSudahMasuk) {
      tampilkanPesan(
        context,
        pesanGagalPerbaruiProfil(KesalahanProfil.belumMasuk),
      );
      return;
    }

    String? namaBaru = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WarnaCapify.coklatGelap,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (konteksLembar) =>
          LembarEditNama(namaSekarang: authProvider.namaTampilan),
    );
    if (!mounted || namaBaru == null) return;

    KesalahanProfil? kesalahan = await authProvider.perbaruiNama(namaBaru);
    if (!mounted) return;

    tampilkanPesan(
      context,
      kesalahan == null
          ? 'Nama berhasil diperbarui'
          : pesanGagalPerbaruiProfil(kesalahan),
    );
  }

  void ubahModeHematData(bool isDinyalakan) {
    bool isKualitasHarusTurun = isDinyalakan && kualitasStreaming == 'Tinggi';

    setState(() {
      isHematData = isDinyalakan;
      if (isKualitasHarusTurun) kualitasStreaming = 'Rendah';
    });

    if (isKualitasHarusTurun) {
      tampilkanPesan(
        context,
        'Kualitas streaming diturunkan ke Rendah biar hemat kuota',
      );
    }
  }

  Future<void> bukaPilihanKualitas() async {
    String? kualitasDipilih = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: WarnaCapify.coklatGelap,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (konteksSheet) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Kualitas Streaming',
                  style: TextStyle(
                    color: WarnaCapify.putih,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (String kualitas in pilihanKualitasStreaming)
                buildPilihanKualitas(konteksSheet, kualitas),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || kualitasDipilih == null) return;
    setState(() => kualitasStreaming = kualitasDipilih);
  }

  Widget buildPilihanKualitas(BuildContext konteksSheet, String kualitas) {
    bool isTerkunciHematData = isHematData && kualitas == 'Tinggi';
    bool isSedangDipakai = kualitas == kualitasStreaming;

    return ListTile(
      enabled: !isTerkunciHematData,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        kualitas,
        style: TextStyle(
          fontWeight: isSedangDipakai ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        isTerkunciHematData
            ? 'Matikan mode hemat data dulu'
            : keteranganKualitas[kualitas] ?? '',
      ),
      trailing: isSedangDipakai
          ? const Icon(Icons.check_circle_rounded, color: WarnaCapify.krem)
          : null,
      onTap: () => Navigator.pop(konteksSheet, kualitas),
    );
  }

  Future<void> konfirmasiKeluar() async {
    bool? isYakinKeluar = await showDialog<bool>(
      context: context,
      builder: (konteksDialog) {
        return AlertDialog(
          backgroundColor: WarnaCapify.coklatGelap,
          title: const Text('Keluar dari Capify?'),
          content: const Text(
            'Kamu perlu masuk lagi untuk mendengarkan lagu favoritmu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(konteksDialog, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: WarnaCapify.krem),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(konteksDialog, true),
              child: const Text(
                'Keluar',
                style: TextStyle(
                  color: warnaPeringatan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || isYakinKeluar != true) return;

    setState(() => isSedangKeluar = true);
    context.read<AudioProvider>().jeda();
    context.read<SearchProvider>().bersihkanSemuaPencarian();
    await context.read<AuthProvider>().keluar();
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (halamanSebelumnya) => false,
    );
  }

  void bukaTentangAplikasi() {
    showAboutDialog(
      context: context,
      applicationName: 'Capify',
      applicationVersion: 'Versi 1.0.0',
      applicationIcon: const CircleAvatar(
        backgroundColor: WarnaCapify.krem,
        child: Icon(Icons.headphones_rounded, color: WarnaCapify.coklatGelap),
      ),
      children: const [
        Text('Aplikasi music streaming buatan Kelompok 3 Mobile Programming.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        foregroundColor: WarnaCapify.putih,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profil & Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          buildKartuProfil(authProvider),
          const SizedBox(height: 28),
          const JudulBagianPengaturan(judul: 'Pemutaran'),
          KartuGrupPengaturan(
            isiGrup: [
              buildSaklarPengaturan(
                ikon: Icons.play_circle_outline_rounded,
                judul: 'Putar otomatis',
                keterangan: 'Lanjut putar lagu serupa saat antrian habis',
                nilai: isPutarOtomatis,
                onUbah: (nilaiBaru) {
                  setState(() => isPutarOtomatis = nilaiBaru);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.graphic_eq_rounded,
                  color: WarnaCapify.krem,
                ),
                title: const Text('Kualitas streaming'),
                subtitle: Text(kualitasStreaming),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: bukaPilihanKualitas,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const JudulBagianPengaturan(judul: 'Aplikasi'),
          KartuGrupPengaturan(
            isiGrup: [
              buildSaklarPengaturan(
                ikon: Icons.notifications_none_rounded,
                judul: 'Notifikasi',
                keterangan: 'Kabar rilisan baru dari penyanyi favoritmu',
                nilai: isNotifikasiAktif,
                onUbah: (nilaiBaru) {
                  setState(() => isNotifikasiAktif = nilaiBaru);
                },
              ),
              buildSaklarPengaturan(
                ikon: Icons.data_saver_on_rounded,
                judul: 'Mode hemat data',
                keterangan: 'Kualitas Tinggi tidak bisa dipilih saat aktif',
                nilai: isHematData,
                onUbah: ubahModeHematData,
              ),
              ListTile(
                leading: const Icon(
                  Icons.language_rounded,
                  color: WarnaCapify.krem,
                ),
                title: const Text('Bahasa'),
                subtitle: const Text('Indonesia'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    tampilkanPesan(context, 'Pilihan bahasa lain segera hadir'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const JudulBagianPengaturan(judul: 'Akun'),
          KartuGrupPengaturan(
            isiGrup: [
              ListTile(
                leading: const Icon(
                  Icons.lock_outline_rounded,
                  color: WarnaCapify.krem,
                ),
                title: const Text('Ubah password'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    tampilkanPesan(context, 'Fitur ubah password segera hadir'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: WarnaCapify.krem,
                ),
                title: const Text('Tentang Capify'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: bukaTentangAplikasi,
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isSedangKeluar ? null : konfirmasiKeluar,
              icon: isSedangKeluar
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: warnaPeringatan,
                      ),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(
                isSedangKeluar ? 'Sedang keluar...' : 'Keluar',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: warnaPeringatan,
                disabledForegroundColor: warnaPeringatan,
                side: const BorderSide(color: warnaPeringatan),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildKartuProfil(AuthProvider authProvider) {
    String namaPengguna = authProvider.namaTampilan;
    String emailPengguna = authProvider.emailTampilan;
    String inisial = authProvider.penggunaAktif?.inisial ?? 'C';
    bool isSedangMenyimpan = authProvider.isSedangMenyimpanProfil;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WarnaCapify.coklatTua, WarnaCapify.hitam],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WarnaCapify.krem.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: WarnaCapify.krem,
                child: Text(
                  inisial,
                  style: const TextStyle(
                    color: WarnaCapify.coklatGelap,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaPengguna,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WarnaCapify.putih,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emailPengguna,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: WarnaCapify.krem.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: WarnaCapify.krem.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Akun Gratis',
                        style: TextStyle(
                          color: WarnaCapify.krem,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              buildAngkaStatistik(daftarPlaylistDummy.length, 'Playlist'),
              buildGarisPemisahStatistik(),
              buildAngkaStatistik(jumlahLaguDisimpan, 'Lagu Disimpan'),
              buildGarisPemisahStatistik(),
              buildAngkaStatistik(daftarRiwayatPutarDummy.length, 'Diputar'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSedangMenyimpan ? null : bukaEditNama,
              icon: isSedangMenyimpan
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: WarnaCapify.krem,
                      ),
                    )
                  : const Icon(Icons.edit_outlined, size: 18),
              label: Text(isSedangMenyimpan ? 'Menyimpan...' : 'Edit Profil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: WarnaCapify.krem,
                disabledForegroundColor: WarnaCapify.krem,
                side: BorderSide(
                  color: WarnaCapify.krem.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAngkaStatistik(int angka, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$angka',
            style: const TextStyle(
              color: WarnaCapify.putih,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WarnaCapify.krem.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGarisPemisahStatistik() {
    return Container(
      width: 1,
      height: 32,
      color: WarnaCapify.krem.withValues(alpha: 0.2),
    );
  }

  Widget buildSaklarPengaturan({
    required IconData ikon,
    required String judul,
    required String keterangan,
    required bool nilai,
    required ValueChanged<bool> onUbah,
  }) {
    return SwitchListTile(
      secondary: Icon(ikon, color: WarnaCapify.krem),
      title: Text(judul),
      subtitle: Text(keterangan),
      value: nilai,
      onChanged: onUbah,
      activeThumbColor: WarnaCapify.coklatGelap,
      activeTrackColor: WarnaCapify.krem,
    );
  }
}

class JudulBagianPengaturan extends StatelessWidget {
  final String judul;

  const JudulBagianPengaturan({super.key, required this.judul});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        judul.toUpperCase(),
        style: TextStyle(
          color: WarnaCapify.krem.withValues(alpha: 0.7),
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class KartuGrupPengaturan extends StatelessWidget {
  final List<Widget> isiGrup;

  const KartuGrupPengaturan({super.key, required this.isiGrup});

  @override
  Widget build(BuildContext context) {
    List<Widget> isiDenganGaris = [];
    for (int urutan = 0; urutan < isiGrup.length; urutan++) {
      if (urutan > 0) {
        isiDenganGaris.add(
          Divider(
            height: 1,
            indent: 56,
            color: WarnaCapify.krem.withValues(alpha: 0.1),
          ),
        );
      }
      isiDenganGaris.add(isiGrup[urutan]);
    }

    return Material(
      color: WarnaCapify.coklatTua.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(children: isiDenganGaris),
    );
  }
}
