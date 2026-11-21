import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lagu.dart';
import '../providers/audio_provider.dart';
import '../utils/warna_capify.dart';
import '../widgets/mini_player.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'player_screen.dart';
import 'playlist_screen.dart';
import 'search_screen.dart';

class HalamanUtamaScreen extends StatefulWidget {
  final String namaPengguna;

  const HalamanUtamaScreen({super.key, this.namaPengguna = 'Capy Lovers'});

  @override
  State<HalamanUtamaScreen> createState() => _HalamanUtamaScreenState();
}

class _HalamanUtamaScreenState extends State<HalamanUtamaScreen> {
  int indexTabAktif = 0;

  void pilihTab(int indexTab) {
    if (indexTab == indexTabAktif) return;
    setState(() => indexTabAktif = indexTab);
  }

  void laguBerikutnyaDariMiniPlayer(AudioProvider audio) {
    bool isBerhasilPindah = audio.laguBerikutnya();
    if (isBerhasilPindah) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Ini sudah lagu terakhir di antrian')),
      );
  }

  @override
  Widget build(BuildContext context) {
    AudioProvider audio = context.watch<AudioProvider>();
    Lagu? lagu = audio.laguSekarang;

    return Scaffold(
      body: IndexedStack(
        index: indexTabAktif,
        children: [
          HomeScreen(namaPengguna: widget.namaPengguna),
          const SearchScreen(),
          const ExploreScreen(),
          const PlaylistScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lagu != null)
            Container(
              color: WarnaCapify.coklatGelap,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: MiniPlayer(
                lagu: lagu,
                isLaguSedangDiputar: audio.isLaguSedangDiputar,
                isSedangMemuat: audio.isSedangMemuat,
                pesanError: audio.pesanError,
                pesanInterupsi: audio.pesanInterupsi,
                onTekanMiniPlayer: () => PlayerScreen.bukaLayarPenuh(context),
                onTekanPlay: audio.togglePutarJeda,
                onTekanNext: () => laguBerikutnyaDariMiniPlayer(audio),
              ),
            ),
          buildNavigasiBawah(),
        ],
      ),
    );
  }

  Widget buildNavigasiBawah() {
    return BottomNavigationBar(
      currentIndex: indexTabAktif,
      onTap: pilihTab,
      type: BottomNavigationBarType.fixed,
      backgroundColor: WarnaCapify.hitam,
      selectedItemColor: WarnaCapify.putih,
      unselectedItemColor: Colors.white54,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          activeIcon: Icon(Icons.manage_search_rounded),
          label: 'Cari',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore_rounded),
          label: 'Jelajah',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music_outlined),
          activeIcon: Icon(Icons.library_music_rounded),
          label: 'Koleksi',
        ),
      ],
    );
  }
}
