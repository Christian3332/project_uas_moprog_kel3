import 'package:flutter/material.dart';

import '../data/kategori_dummy.dart';
import '../models/kategori_musik.dart';
import '../utils/warna_capify.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool isKategoriSedangDimuat = true;
  List<KategoriMusik> daftarKategori = [];

  @override
  void initState() {
    super.initState();
    muatDaftarKategori();
  }

  Future<void> muatDaftarKategori() async {
    setState(() => isKategoriSedangDimuat = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      daftarKategori = List.of(daftarKategoriDummy);
      isKategoriSedangDimuat = false;
    });
  }

  void bukaKategori(KategoriMusik kategoriDipilih) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Daftar lagu ${kategoriDipilih.nama} segera hadir'),
        ),
      );
  }

  Widget bangunIsiHalaman() {
    if (isKategoriSedangDimuat) {
      return const Center(
        child: CircularProgressIndicator(color: WarnaCapify.krem),
      );
    }

    if (daftarKategori.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 32),
        children: const [
          Icon(Icons.category_outlined, size: 48, color: WarnaCapify.krem),
          SizedBox(height: 12),
          Text(
            'Kategori belum tersedia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: WarnaCapify.putih,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tarik ke bawah untuk mencoba memuat ulang',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WarnaCapify.krem,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      itemCount: daftarKategori.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, urutan) {
        KategoriMusik kategoriIni = daftarKategori[urutan];
        return KartuKategori(
          kategori: kategoriIni,
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
          'Jelajahi',
          style: TextStyle(
            fontSize: 20,
            color: WarnaCapify.putih,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Text(
                'Telusuri semua kategori',
                style: TextStyle(
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
                onRefresh: muatDaftarKategori,
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
  final VoidCallback onDitekan;

  const KartuKategori({
    super.key,
    required this.kategori,
    required this.onDitekan,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Icon(
                      kategori.ikon,
                      size: 64,
                      color: WarnaCapify.krem.withValues(alpha: 0.35),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
