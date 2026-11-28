import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const int indexTabHome = 0;
  static const int indexTabCari = 1;
  static const EdgeInsets jarakMiniPlayer = EdgeInsets.fromLTRB(8, 8, 8, 2);

  int indexTabAktif = indexTabHome;
  final List<GlobalKey<NavigatorState>> kunciNavigatorTab = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  NavigatorState? get navigatorTabAktif =>
      kunciNavigatorTab[indexTabAktif].currentState;

  void pilihTab(int indexTab) {
    if (indexTab == indexTabAktif) {
      navigatorTabAktif?.popUntil((rute) => rute.isFirst);
      return;
    }
    setState(() => indexTabAktif = indexTab);
  }

  void tanganiTombolKembali() {
    NavigatorState? navigatorTab = navigatorTabAktif;
    if (navigatorTab != null && navigatorTab.canPop()) {
      navigatorTab.pop();
      return;
    }
    if (indexTabAktif != indexTabHome) {
      setState(() => indexTabAktif = indexTabHome);
      return;
    }
    SystemNavigator.pop();
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

  Widget buatNavigatorTab(int indexTab, Widget halamanAwal) {
    return Navigator(
      key: kunciNavigatorTab[indexTab],
      onGenerateRoute: (pengaturanRute) => MaterialPageRoute(
        settings: pengaturanRute,
        builder: (context) => halamanAwal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AudioProvider audio = context.watch<AudioProvider>();
    Lagu? lagu = audio.laguSekarang;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (isSudahKembali, hasil) {
        if (isSudahKembali) return;
        tanganiTombolKembali();
      },
      child: Scaffold(
        body: IndexedStack(
          index: indexTabAktif,
          children: [
            buatNavigatorTab(0, HomeScreen(namaPengguna: widget.namaPengguna)),
            buatNavigatorTab(indexTabCari, const SearchScreen()),
            buatNavigatorTab(2, const ExploreScreen()),
            buatNavigatorTab(
              3,
              PlaylistScreen(onCariLagu: () => pilihTab(indexTabCari)),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lagu != null)
              Container(
                color: WarnaCapify.hitam,
                padding: jarakMiniPlayer,
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
          label: 'Beranda',
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
