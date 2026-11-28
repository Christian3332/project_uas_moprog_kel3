import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/katalog_pencarian_dummy.dart';
import '../models/album.dart';
import '../models/lagu.dart';
import '../providers/audio_provider.dart';
import '../providers/search_provider.dart';
import '../utils/warna_capify.dart';
import '../widgets/cover_album.dart';
import 'detail_album_screen.dart';
import 'player_screen.dart';

const double lengkungKolomCari = 26;

String buatKunciLagu(Lagu lagu) => '${lagu.judul}|${lagu.penyanyi}';

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
        buatKunciLagu(laguDiPemutar) == buatKunciLagu(laguDipilih);
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
        return laguDiPemutar == null ? null : buatKunciLagu(laguDiPemutar);
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
        kataTunggalUntukDicoba: pencarian.kataTunggalUntukDicoba,
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
    return kunciLaguAktif == buatKunciLagu(lagu);
  }
}

class BarisHasilLagu extends StatelessWidget {
  final Lagu lagu;
  final List<String> kataSorotanJudul;
  final List<String> kataSorotanPenyanyi;
  final VoidCallback onDipilih;
  final VoidCallback onLihatAlbum;
  final bool isLaguAktif;
  final bool isSedangDiputar;
  final bool isSedangMemuat;

  const BarisHasilLagu({
    super.key,
    required this.lagu,
    required this.kataSorotanJudul,
    required this.kataSorotanPenyanyi,
    required this.onDipilih,
    required this.onLihatAlbum,
    this.isLaguAktif = false,
    this.isSedangDiputar = false,
    this.isSedangMemuat = false,
  });

  Widget tandaDiCover() {
    Widget isiTanda;
    if (isSedangMemuat) {
      isiTanda = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: WarnaCapify.krem,
        ),
      );
    } else {
      isiTanda = Icon(
        isSedangDiputar ? Icons.graphic_eq_rounded : Icons.pause_rounded,
        color: WarnaCapify.krem,
        size: 28,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: WarnaCapify.coklatGelap.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: isiTanda,
    );
  }

  String formatDurasi(Duration durasi) {
    String menit = durasi.inMinutes.toString();
    String detik = (durasi.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  List<TextSpan> sorotiKataYangCocok(
    String teksAsli,
    List<String> kataDicari,
    TextStyle gayaBiasa,
    TextStyle gayaSorotan,
  ) {
    String teksHurufKecil = teksAsli.toLowerCase();

    bool panjangnyaBerubah = teksHurufKecil.length != teksAsli.length;
    if (teksAsli.isEmpty || kataDicari.isEmpty || panjangnyaBerubah) {
      return [TextSpan(text: teksAsli, style: gayaBiasa)];
    }

    List<bool> hurufDistabilo = List.filled(teksAsli.length, false);
    for (String kata in kataDicari) {
      int posisiKetemu = teksHurufKecil.indexOf(kata);
      while (posisiKetemu != -1) {
        for (int i = posisiKetemu; i < posisiKetemu + kata.length; i++) {
          hurufDistabilo[i] = true;
        }
        posisiKetemu = teksHurufKecil.indexOf(kata, posisiKetemu + kata.length);
      }
    }

    List<TextSpan> potonganTeks = [];
    int awalPotongan = 0;
    for (int i = 1; i <= teksAsli.length; i++) {
      bool sudahDiUjung = i == teksAsli.length;
      if (sudahDiUjung || hurufDistabilo[i] != hurufDistabilo[awalPotongan]) {
        potonganTeks.add(
          TextSpan(
            text: teksAsli.substring(awalPotongan, i),
            style: hurufDistabilo[awalPotongan] ? gayaSorotan : gayaBiasa,
          ),
        );
        awalPotongan = i;
      }
    }

    return potonganTeks;
  }

  @override
  Widget build(BuildContext context) {
    TextStyle gayaJudul = TextStyle(
      color: isLaguAktif ? WarnaCapify.krem : WarnaCapify.putih,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    const gayaPenyanyi = TextStyle(color: WarnaCapify.krem, fontSize: 13);
    Color warnaStabilo = WarnaCapify.krem.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isLaguAktif
            ? WarnaCapify.coklatTua
            : WarnaCapify.coklatTua.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onDipilih,
          splashColor: WarnaCapify.krem.withValues(alpha: 0.12),
          highlightColor: WarnaCapify.krem.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverAlbum(
                        urlCover: lagu.urlCover,
                        lengkungSudut: 10,
                        isPakaiBayangan: false,
                      ),
                      if (isLaguAktif) tandaDiCover(),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: sorotiKataYangCocok(
                            lagu.judul,
                            kataSorotanJudul,
                            gayaJudul,
                            gayaJudul.copyWith(
                              fontWeight: FontWeight.w800,
                              backgroundColor: warnaStabilo,
                            ),
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: WarnaCapify.krem,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Lagu',
                              style: TextStyle(
                                color: WarnaCapify.coklatGelap,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: sorotiKataYangCocok(
                                  lagu.penyanyi,
                                  kataSorotanPenyanyi,
                                  gayaPenyanyi,
                                  gayaPenyanyi.copyWith(
                                    color: WarnaCapify.putih,
                                    fontWeight: FontWeight.w700,
                                    backgroundColor: warnaStabilo,
                                  ),
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formatDurasi(lagu.durasi),
                  style: TextStyle(
                    color: WarnaCapify.krem.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  onPressed: onLihatAlbum,
                  tooltip: 'Lihat album',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.album_outlined,
                    color: WarnaCapify.krem.withValues(alpha: 0.7),
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

class TampilanHasilKosong extends StatelessWidget {
  final String kataKunci;
  final String? saranEjaan;
  final String? kataTunggalUntukDicoba;
  final bool isPakaiDataOffline;
  final ValueChanged<String> onPakaiKataLain;
  final VoidCallback onHapusPencarian;

  const TampilanHasilKosong({
    super.key,
    required this.kataKunci,
    required this.saranEjaan,
    required this.kataTunggalUntukDicoba,
    required this.isPakaiDataOffline,
    required this.onPakaiKataLain,
    required this.onHapusPencarian,
  });

  List<String> susunTips() {
    return [
      'Periksa lagi ejaannya, satu huruf saja bisa bikin beda',
      if (kataTunggalUntukDicoba != null)
        'Pakai kata yang lebih sedikit atau lebih umum',
      'Coba cari pakai nama penyanyinya',
    ];
  }

  @override
  Widget build(BuildContext context) {
    String keterangan = isPakaiDataOffline
        ? 'Server belum bisa dihubungi, jadi pencarian ini cuma dari data offline yang isinya terbatas'
        : 'Belum ada lagu atau album yang cocok di katalog Capify';

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      children: [
        Icon(
          isPakaiDataOffline ? Icons.cloud_off_rounded : Icons.search_off,
          size: 56,
          color: WarnaCapify.krem,
        ),
        const SizedBox(height: 12),
        Text(
          'Tidak ada hasil untuk "$kataKunci"',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WarnaCapify.putih,
            fontSize: 16,
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
        if (saranEjaan != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Mungkin maksudmu',
            textAlign: TextAlign.center,
            style: TextStyle(color: WarnaCapify.krem, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Center(
            child: ActionChip(
              avatar: const Icon(
                Icons.auto_fix_high_rounded,
                size: 18,
                color: WarnaCapify.coklatGelap,
              ),
              label: Text(saranEjaan!),
              labelStyle: const TextStyle(
                color: WarnaCapify.coklatGelap,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: WarnaCapify.krem,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              onPressed: () => onPakaiKataLain(saranEjaan!),
            ),
          ),
        ],
        if (kataTunggalUntukDicoba != null) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => onPakaiKataLain(kataTunggalUntukDicoba!),
              icon: const Icon(Icons.short_text_rounded),
              label: Text('Cari "$kataTunggalUntukDicoba" saja'),
              style: OutlinedButton.styleFrom(
                foregroundColor: WarnaCapify.krem,
                side: const BorderSide(color: WarnaCapify.krem),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WarnaCapify.coklatTua.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tips biar ketemu',
                style: TextStyle(
                  color: WarnaCapify.putih,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (String tips in susunTips())
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: WarnaCapify.krem,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tips,
                          style: const TextStyle(
                            color: WarnaCapify.krem,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: onHapusPencarian,
            child: const Text(
              'Hapus pencarian',
              style: TextStyle(color: WarnaCapify.krem),
            ),
          ),
        ),
      ],
    );
  }
}

class JudulBagianHasil extends StatelessWidget {
  final String teks;

  const JudulBagianHasil({super.key, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 16,
          color: WarnaCapify.putih,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CatatanDataCadangan extends StatelessWidget {
  const CatatanDataCadangan({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WarnaCapify.coklatTua,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: WarnaCapify.krem),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Server belum bisa dihubungi, ini hasil dari data offline',
              style: TextStyle(color: WarnaCapify.krem, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class KartuAlbumHasil extends StatelessWidget {
  final Album album;
  final VoidCallback onDipilih;

  const KartuAlbumHasil({
    super.key,
    required this.album,
    required this.onDipilih,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: InkWell(
        onTap: onDipilih,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 124,
              height: 124,
              child: CoverAlbum(
                urlCover: album.urlCover,
                lengkungSudut: 12,
                isPakaiBayangan: false,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.judul,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WarnaCapify.putih,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${album.penyanyi} • ${album.jumlahLagu} lagu',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: WarnaCapify.krem.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PesanPencarianKosong extends StatelessWidget {
  final IconData ikon;
  final String pesan;
  final String? keterangan;
  final String? teksTombol;
  final VoidCallback? onTombolDitekan;

  const PesanPencarianKosong({
    super.key,
    required this.ikon,
    required this.pesan,
    this.keterangan,
    this.teksTombol,
    this.onTombolDitekan,
  });

  @override
  Widget build(BuildContext context) {
    bool adaTombol = teksTombol != null && onTombolDitekan != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 56, color: WarnaCapify.krem),
            const SizedBox(height: 12),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WarnaCapify.putih,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (keterangan != null) ...[
              const SizedBox(height: 6),
              Text(
                keterangan!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: WarnaCapify.krem,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
            if (adaTombol) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onTombolDitekan,
                style: OutlinedButton.styleFrom(
                  foregroundColor: WarnaCapify.krem,
                  side: const BorderSide(color: WarnaCapify.krem),
                  shape: const StadiumBorder(),
                ),
                child: Text(teksTombol!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
