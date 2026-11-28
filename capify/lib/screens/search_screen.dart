import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/katalog_pencarian_dummy.dart';
import '../models/album.dart';
import '../models/lagu.dart';
import '../providers/audio_provider.dart';
import '../providers/search_provider.dart';
import '../utils/kunci_lagu.dart';
import '../utils/warna_capify.dart';
import '../widgets/komponen_pencarian.dart';
import 'detail_album_screen.dart';
import 'player_screen.dart';

const double lengkungKolomCari = 26;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController kataKunciController;
  final fokusKolomCari = FocusNode();

  @override
  void initState() {
    super.initState();
    String kataKunciTersimpan = context.read<SearchProvider>().kataKunci;
    kataKunciController = TextEditingController(text: kataKunciTersimpan);
  }

  @override
  void dispose() {
    kataKunciController.dispose();
    fokusKolomCari.dispose();
    super.dispose();
  }

  void pakaiKataKunci(String kataKunci) {
    SearchProvider pencarian = context.read<SearchProvider>();
    kataKunciController.text = kataKunci;
    kataKunciController.selection = TextSelection.collapsed(
      offset: kataKunci.length,
    );
    fokusKolomCari.unfocus();
    pencarian.simpanKeRiwayat(kataKunci);
    pencarian.cariSekarang(kataKunci);
  }

  String ringkasKataKunci(String kataKunci) {
    const int batasTampil = 28;
    if (kataKunci.length <= batasTampil) return kataKunci;
    return '${kataKunci.substring(0, batasTampil).trimRight()}…';
  }

  void kirimPencarian(String kataKunci) {
    SearchProvider pencarian = context.read<SearchProvider>();
    pencarian.simpanKeRiwayat(kataKunci);
    pencarian.cariSekarang(kataKunci);
  }

  void hapusKataKunci() {
    kataKunciController.clear();
    fokusKolomCari.requestFocus();
    context.read<SearchProvider>().kosongkanPencarian();
  }

  void tampilkanPesanSingkat(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  void putarLaguDariHasil(List<Lagu> semuaHasil, int indexDipilih) {
    if (indexDipilih < 0 || indexDipilih >= semuaHasil.length) return;
    fokusKolomCari.unfocus();

    AudioProvider audio = context.read<AudioProvider>();
    SearchProvider pencarian = context.read<SearchProvider>();
    if (!audio.mintaIzinPemutaran()) return;

    pencarian.simpanKeRiwayat(kataKunciController.text);
    Lagu laguDipilih = semuaHasil[indexDipilih];
    Lagu? laguDiPemutar = audio.laguSekarang;

    bool isLaguYangSamaSudahAktif =
        laguDiPemutar != null &&
        kunciUnikLagu(laguDiPemutar) == kunciUnikLagu(laguDipilih);
    if (isLaguYangSamaSudahAktif) {
      if (!audio.isLaguSedangDiputar && !audio.isSedangMemuat) audio.putar();
      PlayerScreen.bukaLayarPenuh(context);
      return;
    }

    if (pencarian.isHasilDariCadangan) {
      tampilkanPesanSingkat(
        'Server sedang tidak terjangkau, lagu mungkin gagal diputar',
      );
    }

    audio.mulaiAntrian(
      semuaHasil,
      indexMulai: indexDipilih,
      namaAntrian:
          'Hasil cari "${ringkasKataKunci(pencarian.kataKunciBersih)}"',
    );
  }

  void lihatAlbumDariLagu(Lagu lagu) {
    Album? albumLagu = cariAlbumDariLagu(lagu);
    if (albumLagu == null) {
      tampilkanPesanSingkat(
        'Lagu "${lagu.judul}" belum masuk ke album mana pun',
      );
      return;
    }

    bukaDetailAlbum(albumLagu);
  }

  void bukaDetailAlbum(Album album) {
    fokusKolomCari.unfocus();
    context.read<SearchProvider>().simpanKeRiwayat(kataKunciController.text);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailAlbumScreen(album: album)),
    );
  }

  @override
  Widget build(BuildContext context) {
    SearchProvider pencarian = context.watch<SearchProvider>();
    StatusPemutarDiPencarian statusPemutar = StatusPemutarDiPencarian(
      kunciLaguAktif: context.select<AudioProvider, String?>((audio) {
        Lagu? laguDiPemutar = audio.laguSekarang;
        return laguDiPemutar == null ? null : kunciUnikLagu(laguDiPemutar);
      }),
      isSedangDiputar: context.select<AudioProvider, bool>(
        (audio) => audio.isLaguSedangDiputar,
      ),
      isSedangMemuat: context.select<AudioProvider, bool>(
        (audio) => audio.isSedangMemuat,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: WarnaCapify.coklatGelap,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Cari',
          style: TextStyle(
            fontSize: 22,
            color: WarnaCapify.putih,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: kolomPencarian(pencarian),
            ),
            if (!pencarian.isKolomCariKosong) barisFilter(pencarian),
            Expanded(child: tampilanIsiPencarian(pencarian, statusPemutar)),
          ],
        ),
      ),
    );
  }

  List<BoxShadow> bayanganKolomCari(bool isSedangFokus) {
    return [
      BoxShadow(
        color: WarnaCapify.hitam.withValues(alpha: isSedangFokus ? 0.45 : 0.3),
        blurRadius: isSedangFokus ? 18 : 10,
        offset: Offset(0, isSedangFokus ? 6 : 3),
      ),
    ];
  }

  Widget kolomPencarian(SearchProvider pencarian) {
    BorderRadius sudutKolom = BorderRadius.circular(lengkungKolomCari);
    OutlineInputBorder tepiSaatDiam = OutlineInputBorder(
      borderRadius: sudutKolom,
      borderSide: BorderSide.none,
    );
    OutlineInputBorder tepiSaatFokus = OutlineInputBorder(
      borderRadius: sudutKolom,
      borderSide: BorderSide(
        color: WarnaCapify.coklatTua.withValues(alpha: 0.6),
        width: 1.5,
      ),
    );

    return ListenableBuilder(
      listenable: fokusKolomCari,
      builder: (context, kolomTeks) {
        return AnimatedContainer(
          key: const ValueKey('kotak-kolom-cari'),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: sudutKolom,
            boxShadow: bayanganKolomCari(fokusKolomCari.hasFocus),
          ),
          child: kolomTeks,
        );
      },
      child: TextField(
        controller: kataKunciController,
        focusNode: fokusKolomCari,
        onChanged: pencarian.ketikKataKunci,
        onSubmitted: kirimPencarian,
        onTapOutside: (event) => fokusKolomCari.unfocus(),
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: WarnaCapify.coklatGelap),
        cursorColor: WarnaCapify.coklatGelap,
        decoration: InputDecoration(
          hintText: 'Mau dengar apa hari ini?',
          hintStyle: TextStyle(
            color: WarnaCapify.coklatGelap.withValues(alpha: 0.6),
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.search, color: WarnaCapify.coklatGelap),
          ),
          suffixIcon: pencarian.kataKunci.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: WarnaCapify.coklatGelap,
                    ),
                    tooltip: 'Hapus kata kunci',
                    onPressed: hapusKataKunci,
                  ),
                ),
          filled: true,
          fillColor: WarnaCapify.krem,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: tepiSaatDiam,
          enabledBorder: tepiSaatDiam,
          focusedBorder: tepiSaatFokus,
        ),
      ),
    );
  }

  Widget barisFilter(SearchProvider pencarian) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        children: [
          for (String namaFilter in SearchProvider.pilihanFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(namaFilter),
                selected: pencarian.filterAktif == namaFilter,
                onSelected: (dipilih) => pencarian.gantiFilter(namaFilter),
                showCheckmark: false,
                selectedColor: WarnaCapify.krem,
                backgroundColor: WarnaCapify.coklatTua,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  color: pencarian.filterAktif == namaFilter
                      ? WarnaCapify.coklatGelap
                      : WarnaCapify.krem,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget tampilanIsiPencarian(
    SearchProvider pencarian,
    StatusPemutarDiPencarian statusPemutar,
  ) {
    String kataKunciSekarang = pencarian.kataKunciBersih;
    List<Lagu> hasilPencarian = pencarian.hasilPencarian;

    if (pencarian.isSedangMencari) {
      return const Center(
        child: CircularProgressIndicator(color: WarnaCapify.krem),
      );
    }

    if (pencarian.isKolomCariKosong) {
      return tampilanSebelumMencari(pencarian);
    }

    if (pencarian.isKataKunciKependekan) {
      return PesanPencarianKosong(
        ikon: Icons.keyboard_alt_outlined,
        pesan: 'Ketik minimal ${pencarian.minimalHurufUntukCari} huruf ya',
        keterangan: 'Biar hasilnya lebih pas dan server tidak kerepotan',
      );
    }

    if (pencarian.isAdaError) {
      return PesanPencarianKosong(
        ikon: Icons.wifi_off_rounded,
        pesan: pencarian.pesanError!,
        keterangan: 'Kata kuncimu tetap tersimpan, tinggal coba lagi',
        teksTombol: 'Coba lagi',
        onTombolDitekan: pencarian.cobaLagi,
      );
    }

    if (pencarian.isHasilTersembunyiOlehFilter) {
      int jumlahTersembunyi = pencarian.jumlahHasilTanpaFilter;
      return PesanPencarianKosong(
        ikon: Icons.filter_alt_off_outlined,
        pesan:
            'Tidak ada ${pencarian.filterAktif.toLowerCase()} yang cocok dengan "${ringkasKataKunci(kataKunciSekarang)}"',
        keterangan:
            'Tapi ada $jumlahTersembunyi hasil lain kalau filternya dilepas',
        teksTombol: 'Lihat $jumlahTersembunyi hasil',
        onTombolDitekan: () =>
            pencarian.gantiFilter(SearchProvider.filterSemua),
      );
    }

    if (pencarian.isHasilKosong) {
      return TampilanHasilKosong(
        kataKunci: ringkasKataKunci(kataKunciSekarang),
        saranEjaan: pencarian.saranEjaan,
        isPakaiDataOffline: pencarian.isHasilDariCadangan,
        onPakaiKataLain: pakaiKataKunci,
        onHapusPencarian: hapusKataKunci,
      );
    }

    List<Album> albumDitemukan = pencarian.albumDitemukan;
    List<String> ringkasanJumlah = [
      if (hasilPencarian.isNotEmpty) '${hasilPencarian.length} lagu',
      if (albumDitemukan.isNotEmpty) '${albumDitemukan.length} album',
    ];

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (pencarian.isHasilDariCadangan) const CatatanDataCadangan(),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${ringkasanJumlah.join(' • ')} ditemukan',
            style: TextStyle(
              color: WarnaCapify.krem.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
        if (albumDitemukan.isNotEmpty) ...[
          const JudulBagianHasil(teks: 'Album'),
          SizedBox(
            height: 186,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: albumDitemukan.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                Album albumIni = albumDitemukan[index];
                return KartuAlbumHasil(
                  album: albumIni,
                  onDipilih: () => bukaDetailAlbum(albumIni),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (hasilPencarian.isNotEmpty) ...[
          if (albumDitemukan.isNotEmpty) const JudulBagianHasil(teks: 'Lagu'),
          for (int urutan = 0; urutan < hasilPencarian.length; urutan++)
            BarisHasilLagu(
              lagu: hasilPencarian[urutan],
              kataSorotanJudul: pencarian.kataSorotanJudul,
              kataSorotanPenyanyi: pencarian.kataSorotanPenyanyi,
              isLaguAktif: statusPemutar.isLaguIni(hasilPencarian[urutan]),
              isSedangDiputar: statusPemutar.isSedangDiputar,
              isSedangMemuat: statusPemutar.isSedangMemuat,
              onDipilih: () => putarLaguDariHasil(hasilPencarian, urutan),
              onLihatAlbum: () => lihatAlbumDariLagu(hasilPencarian[urutan]),
            ),
        ],
      ],
    );
  }

  Widget tampilanSebelumMencari(SearchProvider pencarian) {
    List<String> riwayatPencarian = pencarian.riwayatPencarian;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (riwayatPencarian.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: PesanPencarianKosong(
              ikon: Icons.manage_search,
              pesan: 'Cari lagu atau penyanyi favoritmu',
            ),
          )
        else ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pencarian terakhir',
                  style: TextStyle(
                    fontSize: 16,
                    color: WarnaCapify.putih,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: pencarian.hapusSemuaRiwayat,
                child: const Text(
                  'Hapus semua',
                  style: TextStyle(color: WarnaCapify.krem),
                ),
              ),
            ],
          ),
          for (String kataLama in riwayatPencarian)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: WarnaCapify.krem),
              title: Text(
                kataLama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: WarnaCapify.putih),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: WarnaCapify.krem,
                ),
                onPressed: () => pencarian.hapusSatuRiwayat(kataLama),
              ),
              onTap: () => pakaiKataKunci(kataLama),
            ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Coba cari',
          style: TextStyle(
            fontSize: 16,
            color: WarnaCapify.putih,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pencarian.saranPencarian.map((saran) {
            return ActionChip(
              label: Text(saran),
              labelStyle: const TextStyle(color: WarnaCapify.krem),
              backgroundColor: WarnaCapify.coklatTua,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              onPressed: () => pakaiKataKunci(saran),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class StatusPemutarDiPencarian {
  final String? kunciLaguAktif;
  final bool isSedangDiputar;
  final bool isSedangMemuat;

  const StatusPemutarDiPencarian({
    required this.kunciLaguAktif,
    required this.isSedangDiputar,
    required this.isSedangMemuat,
  });

  bool isLaguIni(Lagu lagu) {
    return kunciLaguAktif == kunciUnikLagu(lagu);
  }
}
