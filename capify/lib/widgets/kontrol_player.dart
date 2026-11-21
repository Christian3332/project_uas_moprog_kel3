import 'package:flutter/material.dart';

import '../models/mode_ulang.dart';
import '../utils/warna_capify.dart';

class SeekbarPlayer extends StatefulWidget {
  final Duration posisiSekarang;
  final Duration durasiLagu;
  final Duration posisiTerbuffer;
  final ValueChanged<double> onGeser;

  const SeekbarPlayer({
    super.key,
    required this.posisiSekarang,
    required this.durasiLagu,
    this.posisiTerbuffer = Duration.zero,
    required this.onGeser,
  });

  @override
  State<SeekbarPlayer> createState() => _SeekbarPlayerState();
}

class _SeekbarPlayerState extends State<SeekbarPlayer> {
  double? detikSaatDigeser;

  String formatWaktu(Duration waktu) {
    int menit = waktu.inMinutes;
    int detik = waktu.inSeconds % 60;
    return '$menit:${detik.toString().padLeft(2, '0')}';
  }

  void lepasGeseran(double detikTujuan) {
    if (!mounted) return;
    setState(() => detikSaatDigeser = null);
    widget.onGeser(detikTujuan);
  }

  @override
  Widget build(BuildContext context) {
    double durasiDalamDetik = widget.durasiLagu.inSeconds.toDouble();
    bool isBisaDigeser = durasiDalamDetik > 0;
    double maksSlider = isBisaDigeser ? durasiDalamDetik : 1;
    double posisiSlider =
        (detikSaatDigeser ?? widget.posisiSekarang.inSeconds.toDouble()).clamp(
          0,
          maksSlider,
        );
    Duration posisiYangDitampilkan = Duration(seconds: posisiSlider.round());
    double posisiBuffer = widget.posisiTerbuffer.inSeconds.toDouble().clamp(
      0,
      maksSlider,
    );

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: WarnaCapify.krem,
            inactiveTrackColor: Colors.white24,
            secondaryActiveTrackColor: Colors.white54,
            thumbColor: WarnaCapify.krem,
            overlayColor: WarnaCapify.krem.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: posisiSlider,
            secondaryTrackValue: posisiBuffer,
            min: 0,
            max: maksSlider,
            onChanged: isBisaDigeser
                ? (detikBaru) => setState(() => detikSaatDigeser = detikBaru)
                : null,
            onChangeEnd: isBisaDigeser ? lepasGeseran : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatWaktu(posisiYangDitampilkan),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                formatWaktu(widget.durasiLagu),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TombolKontrolPlayer extends StatelessWidget {
  final bool isLaguSedangDiputar;
  final bool isSedangMemuat;
  final bool isAcak;
  final ModeUlang modeUlang;
  final VoidCallback onTekanPlay;
  final VoidCallback onTekanPrevious;
  final VoidCallback onTekanNext;
  final VoidCallback onTekanAcak;
  final VoidCallback onTekanUlang;

  const TombolKontrolPlayer({
    super.key,
    required this.isLaguSedangDiputar,
    required this.isSedangMemuat,
    required this.isAcak,
    required this.modeUlang,
    required this.onTekanPlay,
    required this.onTekanPrevious,
    required this.onTekanNext,
    required this.onTekanAcak,
    required this.onTekanUlang,
  });

  String tulisanModeUlang() {
    if (modeUlang == ModeUlang.semua) return 'Ulangi semua';
    if (modeUlang == ModeUlang.satu) return 'Ulangi satu lagu';
    return 'Ulangi mati';
  }

  @override
  Widget build(BuildContext context) {
    Color warnaAcak = isAcak ? WarnaCapify.krem : Colors.white54;
    Color warnaUlang = modeUlang == ModeUlang.mati
        ? Colors.white54
        : WarnaCapify.krem;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onTekanAcak,
          tooltip: isAcak ? 'Acak aktif' : 'Acak mati',
          icon: Icon(Icons.shuffle_rounded, color: warnaAcak),
        ),
        IconButton(
          onPressed: onTekanPrevious,
          tooltip: 'Lagu sebelumnya',
          iconSize: 40,
          icon: const Icon(
            Icons.skip_previous_rounded,
            color: WarnaCapify.putih,
          ),
        ),
        GestureDetector(
          onTap: onTekanPlay,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: WarnaCapify.krem,
              shape: BoxShape.circle,
            ),
            child: isSedangMemuat
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: WarnaCapify.coklatGelap,
                    ),
                  )
                : Icon(
                    isLaguSedangDiputar
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 40,
                    color: WarnaCapify.coklatGelap,
                  ),
          ),
        ),
        IconButton(
          onPressed: onTekanNext,
          tooltip: 'Lagu berikutnya',
          iconSize: 40,
          icon: const Icon(Icons.skip_next_rounded, color: WarnaCapify.putih),
        ),
        IconButton(
          onPressed: onTekanUlang,
          tooltip: tulisanModeUlang(),
          icon: Icon(
            modeUlang == ModeUlang.satu
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: warnaUlang,
          ),
        ),
      ],
    );
  }
}
