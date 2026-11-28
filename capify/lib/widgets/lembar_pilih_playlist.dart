import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lagu.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../utils/warna_capify.dart';
import 'cover_album.dart';

class LembarPilihPlaylist extends StatelessWidget {
  final Lagu lagu;

  const LembarPilihPlaylist({super.key, required this.lagu});

  @override
  Widget build(BuildContext context) {
    PlaylistProvider koleksi = context.watch<PlaylistProvider>();
    List<Playlist> daftarPlaylist = koleksi.daftarPlaylistSaya;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Tambah ke playlist',
                style: TextStyle(
                  fontSize: 18,
                  color: WarnaCapify.putih,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${lagu.judul} • ${lagu.penyanyi}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WarnaCapify.krem,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (koleksi.isKoleksiSedangDimuat)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: WarnaCapify.krem),
                ),
              )
            else if (daftarPlaylist.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: Text(
                  'Kamu belum punya playlist. Buat dulu di tab Koleksi ya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: WarnaCapify.krem),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: daftarPlaylist.length,
                  itemBuilder: (context, urutan) {
                    Playlist playlist = daftarPlaylist[urutan];
                    bool isSudahAda = playlist.isPunyaLagu(lagu);

                    return ListTile(
                      enabled: !isSudahAda,
                      onTap: () => Navigator.pop(context, playlist.id),
                      leading: SizedBox(
                        width: 48,
                        height: 48,
                        child: CoverAlbum(
                          urlCover: playlist.urlCoverPlaylist,
                          lengkungSudut: 8,
                          isPakaiBayangan: false,
                        ),
                      ),
                      title: Text(
                        playlist.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WarnaCapify.putih,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        isSudahAda
                            ? 'Lagu ini sudah ada di sini'
                            : '${playlist.daftarLagu.length} lagu',
                        style: const TextStyle(color: WarnaCapify.krem),
                      ),
                      trailing: Icon(
                        isSudahAda
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: WarnaCapify.krem,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
