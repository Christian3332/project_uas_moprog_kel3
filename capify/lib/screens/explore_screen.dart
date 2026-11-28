import 'package:flutter/material.dart';

import '../data/kategori_dummy.dart';
import '../data/lagu_per_kategori_dummy.dart';
import '../models/kategori_musik.dart';
import '../utils/warna_capify.dart';
import '../widgets/sampul_kategori.dart';
import 'detail_kategori_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const String jenisSemua = 'Semua';

  bool isHanyaYangAdaLagu = false;
  String jenisDipilih = jenisSemua;

  List<KategoriMusik> semuaKategori = [];
  Map<String, String?> urlSampulPerKategori = {};
  final Set<String> sampulYangSudahDisiapkan = {};

  List<String> get daftarJenis {
    return {
      jenisSemua,
      ...semuaKategori.map((kategori) => kategori.jenis),
    }.toList();
  }

  bool get isFilterSedangDipakai {
    return jenisDipilih != jenisSemua || isHanyaYangAdaLagu;
  }

  List<KategoriMusik> get kategoriTampil {
    return semuaKategori.where((kategori) {
      bool jenisnyaCocok =
          jenisDipilih == jenisSemua || kategori.jenis == jenisDipilih;
      bool syaratLaguTerpenuhi =
          !isHanyaYangAdaLagu || jumlahLaguDi(kategori) > 0;
      return jenisnyaCocok && syaratLaguTerpenuhi;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    isiDaftarKategori();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    siapkanSampulLebihAwal();
  }

  int jumlahLaguDi(KategoriMusik kategori) {
    return laguPerKategoriDummy[kategori.nama]?.length ?? 0;
  }

  void isiDaftarKategori() {
    semuaKategori = List.of(daftarKategoriDummy);
    urlSampulPerKategori = {
      for (KategoriMusik kategori in semuaKategori)
        kategori.nama: ambilUrlSampulKategori(kategori.nama),
    };
    if (!daftarJenis.contains(jenisDipilih)) {
      jenisDipilih = jenisSemua;
    }
  }

  Future<void> muatUlangKategori() async {
    setState(isiDaftarKategori);
    siapkanSampulLebihAwal();
  }

  void siapkanSampulLebihAwal() {
    double rasioPikselLayar = MediaQuery.devicePixelRatioOf(context);

    for (String? urlSampul in urlSampulPerKategori.values) {
      if (urlSampul == null) continue;
      if (!sampulYangSudahDisiapkan.add(urlSampul)) continue;

      precacheImage(
        buatPenyediaSampul(urlSampul, rasioPikselLayar),
        context,
        onError: (error, jejakError) {
          sampulYangSudahDisiapkan.remove(urlSampul);
        },
      );
    }
  }

  void terapkanFilter({String? jenisBaru, bool? hanyaYangAdaLaguBaru}) {
    setState(() {
      jenisDipilih = jenisBaru ?? jenisDipilih;
      isHanyaYangAdaLagu = hanyaYangAdaLaguBaru ?? isHanyaYangAdaLagu;
    });
  }

  void pilihJenis(String jenisBaru) {
    if (jenisBaru == jenisDipilih) return;
    terapkanFilter(jenisBaru: jenisBaru);
  }

  void resetSemuaFilter() {
    terapkanFilter(jenisBaru: jenisSemua, hanyaYangAdaLaguBaru: false);
  }

  void bukaKategori(KategoriMusik kategoriDipilih) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailKategoriScreen(kategori: kategoriDipilih),
      ),
    );
  }

  String judulBagian() {
    if (jenisDipilih == jenisSemua) return 'Telusuri semua kategori';
    return 'Kategori ${jenisDipilih.toLowerCase()}';
  }

  String pesanSaatKosong() {
    String namaJenis = jenisDipilih == jenisSemua
        ? 'kategori'
        : 'kategori ${jenisDipilih.toLowerCase()}';
    if (isHanyaYangAdaLagu) return 'Belum ada $namaJenis yang punya lagu';
    return 'Belum ada $namaJenis di sini';
  }

  Widget barisFilter() {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        children: [
          for (String jenis in daftarJenis)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(jenis),
                selected: jenisDipilih == jenis,
                onSelected: (dipilih) => pilihJenis(jenis),
                showCheckmark: false,
                selectedColor: WarnaCapify.krem,
                backgroundColor: WarnaCapify.coklatTua,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  color: jenisDipilih == jenis
                      ? WarnaCapify.coklatGelap
                      : WarnaCapify.krem,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            width: 1,
            margin: const EdgeInsets.fromLTRB(4, 6, 12, 6),
            color: WarnaCapify.krem.withValues(alpha: 0.3),
          ),
          FilterChip(
            label: const Text('Ada lagunya'),
            selected: isHanyaYangAdaLagu,
            onSelected: (dicentang) =>
                terapkanFilter(hanyaYangAdaLaguBaru: dicentang),
            checkmarkColor: WarnaCapify.coklatGelap,
            selectedColor: WarnaCapify.krem,
            backgroundColor: WarnaCapify.coklatTua,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            labelStyle: TextStyle(
              color: isHanyaYangAdaLagu
                  ? WarnaCapify.coklatGelap
                  : WarnaCapify.krem,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget tampilanKosong({
    required IconData ikon,
    required String pesan,
    required String keterangan,
    String? teksTombol,
    VoidCallback? onTombolDitekan,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 32),
      children: [
        Icon(ikon, size: 48, color: WarnaCapify.krem),
        const SizedBox(height: 12),
        Text(
          pesan,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: WarnaCapify.putih,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          keterangan,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WarnaCapify.krem,
            fontWeight: FontWeight.w300,
          ),
        ),
        if (teksTombol != null && onTombolDitekan != null) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: onTombolDitekan,
              style: OutlinedButton.styleFrom(
                foregroundColor: WarnaCapify.krem,
                side: const BorderSide(color: WarnaCapify.krem),
                shape: const StadiumBorder(),
              ),
              child: Text(teksTombol),
            ),
          ),
        ],
      ],
    );
  }

  Widget bangunIsiHalaman() {
    List<KategoriMusik> daftarTampil = kategoriTampil;

    if (semuaKategori.isEmpty) {
      return tampilanKosong(
        ikon: Icons.category_outlined,
        pesan: 'Kategori belum tersedia',
        keterangan: 'Tarik ke bawah untuk mencoba memuat ulang',
      );
    }

    if (daftarTampil.isEmpty) {
      return tampilanKosong(
        ikon: Icons.filter_alt_off_outlined,
        pesan: pesanSaatKosong(),
        keterangan: 'Coba longgarkan filternya dulu',
        teksTombol: 'Tampilkan semua',
        onTombolDitekan: resetSemuaFilter,
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      itemCount: daftarTampil.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, urutan) {
        KategoriMusik kategoriIni = daftarTampil[urutan];
        return KartuKategori(
          key: ValueKey(kategoriIni.nama),
          kategori: kategoriIni,
          jumlahLagu: jumlahLaguDi(kategoriIni),
          urlSampul: urlSampulPerKategori[kategoriIni.nama],
          onDitekan: () => bukaKategori(kategoriIni),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Jelajah',
          style: TextStyle(
            fontSize: 20,
            color: WarnaCapify.putih,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isFilterSedangDipakai)
            TextButton(
              onPressed: resetSemuaFilter,
              child: const Text(
                'Reset',
                style: TextStyle(color: WarnaCapify.krem),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (semuaKategori.isNotEmpty) barisFilter(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Text(
                judulBagian(),
                style: const TextStyle(
                  fontSize: 16,
                  color: WarnaCapify.krem,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: WarnaCapify.coklatGelap,
                backgroundColor: WarnaCapify.krem,
                onRefresh: muatUlangKategori,
                child: bangunIsiHalaman(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KartuKategori extends StatelessWidget {
  final KategoriMusik kategori;
  final int jumlahLagu;
  final String? urlSampul;
  final VoidCallback onDitekan;

  const KartuKategori({
    super.key,
    required this.kategori,
    required this.jumlahLagu,
    required this.onDitekan,
    this.urlSampul,
  });

  @override
  Widget build(BuildContext context) {
    bool isSudahAdaLagu = jumlahLagu > 0;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kategori.warnaKartu, WarnaCapify.coklatGelap],
          ),
        ),
        child: InkWell(
          onTap: onDitekan,
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  bottom: -10,
                  width: ukuranSampulKategori,
                  height: ukuranSampulKategori,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: SampulKategori(
                      urlSampul: urlSampul,
                      ikonCadangan: kategori.ikon,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    kategori.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: WarnaCapify.putih,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSudahAdaLagu
                          ? WarnaCapify.krem
                          : WarnaCapify.coklatGelap.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSudahAdaLagu ? '$jumlahLagu lagu' : 'Segera hadir',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSudahAdaLagu
                            ? WarnaCapify.coklatGelap
                            : WarnaCapify.krem,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
