import 'package:flutter/material.dart';

import '../utils/warna_capify.dart';

class CoverAlbum extends StatelessWidget {
  final String urlCover;
  final double lengkungSudut;

  const CoverAlbum({
    super.key,
    required this.urlCover,
    this.lengkungSudut = 16,
  });

  @override
  Widget build(BuildContext context) {
    bool isUrlKosong = urlCover.trim().isEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(lengkungSudut),
        boxShadow: [
          BoxShadow(
            color: WarnaCapify.hitam.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(lengkungSudut),
        child: isUrlKosong
            ? const PlaceholderCover()
            : Image.network(
                urlCover,
                fit: BoxFit.cover,
                loadingBuilder: (context, gambar, progresLoading) {
                  if (progresLoading == null) return gambar;
                  return const PlaceholderCover(isSedangMemuat: true);
                },
                errorBuilder: (context, error, stackTrace) {
                  return const PlaceholderCover();
                },
              ),
      ),
    );
  }
}

class PlaceholderCover extends StatelessWidget {
  final bool isSedangMemuat;

  const PlaceholderCover({super.key, this.isSedangMemuat = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WarnaCapify.coklatTua, WarnaCapify.coklatGelap],
        ),
      ),
      child: Center(
        child: isSedangMemuat
            ? const CircularProgressIndicator(color: WarnaCapify.krem)
            : const Padding(
                padding: EdgeInsets.all(16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 88,
                        color: WarnaCapify.krem,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Capify',
                        style: TextStyle(
                          color: WarnaCapify.krem,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3,
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
