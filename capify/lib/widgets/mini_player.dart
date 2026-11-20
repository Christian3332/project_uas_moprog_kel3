import 'package:flutter/material.dart';

import '../models/lagu.dart';
import '../utils/warna_capify.dart';
import 'cover_album.dart';

class MiniPlayer extends StatelessWidget {
  final Lagu lagu;
  final bool isLaguSedangDiputar;
  final bool isSedangMemuat;
  final String? pesanError;
  final VoidCallback onTekanMiniPlayer;
  final VoidCallback onTekanPlay;
  final VoidCallback onTekanNext;

  const MiniPlayer({
    super.key,
    required this.lagu,
    required this.isLaguSedangDiputar,
    this.isSedangMemuat = false,
    this.pesanError,
    required this.onTekanMiniPlayer,
    required this.onTekanPlay,
    required this.onTekanNext,
  });

  @override
  Widget build(BuildContext context) {
    bool isTampilkanSpinner = isSedangMemuat && !isLaguSedangDiputar;
    bool isAdaError = pesanError != null;

    return Material(
      color: WarnaCapify.coklatTua,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTekanMiniPlayer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CoverAlbum(
                  urlCover: lagu.urlCover,
                  lengkungSudut: 6,
                  isPakaiBayangan: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lagu.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WarnaCapify.putih,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAdaError
                          ? 'Gagal memuat, ketuk play untuk coba lagi'
                          : lagu.penyanyi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isAdaError ? WarnaCapify.krem : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTampilkanSpinner)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: WarnaCapify.krem,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: onTekanPlay,
                  tooltip: isLaguSedangDiputar ? 'Jeda' : 'Putar',
                  icon: Icon(
                    isLaguSedangDiputar
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 30,
                    color: WarnaCapify.putih,
                  ),
                ),
              IconButton(
                onPressed: onTekanNext,
                tooltip: 'Lagu berikutnya',
                icon: const Icon(
                  Icons.skip_next_rounded,
                  size: 28,
                  color: WarnaCapify.putih,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
