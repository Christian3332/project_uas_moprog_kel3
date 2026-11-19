import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/playlist_provider.dart';
import '../utils/warna_capify.dart';
import 'komponen_auth.dart';

class FormBuatPlaylist extends StatefulWidget {
  const FormBuatPlaylist({super.key});

  @override
  State<FormBuatPlaylist> createState() => _FormBuatPlaylistState();
}

class _FormBuatPlaylistState extends State<FormBuatPlaylist> {
  final kunciForm = GlobalKey<FormState>();
  final namaController = TextEditingController();
  final deskripsiController = TextEditingController();
  String? pesanGagalMenyimpan;

  @override
  void dispose() {
    namaController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }

  Future<void> simpanPlaylist() async {
    setState(() => pesanGagalMenyimpan = null);

    bool isIsianValid = kunciForm.currentState?.validate() ?? false;
    if (!isIsianValid) return;

    FocusScope.of(context).unfocus();
    String namaPlaylist = namaController.text.trim();

    String? pesanGagal = await context
        .read<PlaylistProvider>()
        .buatPlaylistBaru(
          nama: namaPlaylist,
          deskripsi: deskripsiController.text,
        );

    if (!mounted) return;

    if (pesanGagal != null) {
      setState(() => pesanGagalMenyimpan = pesanGagal);
      return;
    }

    Navigator.pop(context, namaPlaylist);
  }

  @override
  Widget build(BuildContext context) {
    PlaylistProvider koleksi = context.watch<PlaylistProvider>();
    bool isSedangMenyimpan = koleksi.isSedangMembuatPlaylist;
    String? pesanGagal = pesanGagalMenyimpan;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Form(
            key: kunciForm,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WarnaCapify.krem.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Buat Playlist Baru',
                  style: TextStyle(
                    fontSize: 18,
                    color: WarnaCapify.putih,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kasih nama yang gampang kamu ingat',
                  style: TextStyle(
                    color: WarnaCapify.krem,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 20),
                KolomInputAuth(
                  controller: namaController,
                  petunjukIsian: 'Nama playlist',
                  ikonDepan: Icons.queue_music_rounded,
                  cekIsian: koleksi.cekNamaPlaylistBaru,
                  isBisaDiketik: !isSedangMenyimpan,
                ),
                const SizedBox(height: 12),
                KolomInputAuth(
                  controller: deskripsiController,
                  petunjukIsian: 'Deskripsi (boleh dikosongkan)',
                  ikonDepan: Icons.notes_rounded,
                  aksiKeyboard: TextInputAction.done,
                  saatSelesaiKetik: (_) => simpanPlaylist(),
                  isBisaDiketik: !isSedangMenyimpan,
                ),
                if (pesanGagal != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      pesanGagal,
                      style: const TextStyle(color: Color(0xFFFF8A80)),
                    ),
                  ),
                const SizedBox(height: 20),
                TombolAuth(
                  teksTombol: 'Buat Playlist',
                  isSedangLoading: isSedangMenyimpan,
                  onTekan: simpanPlaylist,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: isSedangMenyimpan
                      ? null
                      : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: WarnaCapify.krem,
                  ),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
