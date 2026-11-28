import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../utils/warna_capify.dart';

const Color warnaPeringatan = Color(0xFFFF8A80);

void tampilkanPesan(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(pesan)));
}

class BatasLebarAuth extends StatelessWidget {
  final Widget child;

  const BatasLebarAuth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: child,
      ),
    );
  }
}

const BoxDecoration latarGradienAuth = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [WarnaCapify.hitam, WarnaCapify.coklatGelap, WarnaCapify.coklatTua],
  ),
);

class HeaderAuth extends StatelessWidget {
  final String judul;
  final String subjudul;

  const HeaderAuth({super.key, required this.judul, required this.subjudul});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: WarnaCapify.krem,
            shape: BoxShape.circle,
            border: Border.all(color: WarnaCapify.coklatTua, width: 3),
          ),
          child: const Icon(
            Icons.headphones_rounded,
            size: 44,
            color: WarnaCapify.coklatGelap,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          judul,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WarnaCapify.putih,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subjudul,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: WarnaCapify.krem.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class KolomInputAuth extends StatelessWidget {
  final TextEditingController controller;
  final String petunjukIsian;
  final IconData ikonDepan;
  final bool isTeksDisembunyikan;
  final Widget? tombolBelakang;
  final TextInputType jenisKeyboard;
  final TextInputAction aksiKeyboard;
  final String? Function(String?)? cekIsian;
  final ValueChanged<String>? saatSelesaiKetik;
  final bool isBisaDiketik;
  final Iterable<String>? jenisAutofill;

  const KolomInputAuth({
    super.key,
    required this.controller,
    required this.petunjukIsian,
    required this.ikonDepan,
    this.isTeksDisembunyikan = false,
    this.tombolBelakang,
    this.jenisKeyboard = TextInputType.text,
    this.aksiKeyboard = TextInputAction.next,
    this.cekIsian,
    this.saatSelesaiKetik,
    this.isBisaDiketik = true,
    this.jenisAutofill,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder garisKolom = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    return TextFormField(
      controller: controller,
      obscureText: isTeksDisembunyikan,
      keyboardType: jenisKeyboard,
      textInputAction: aksiKeyboard,
      validator: cekIsian,
      onFieldSubmitted: saatSelesaiKetik,
      readOnly: !isBisaDiketik,
      autofillHints: kIsWeb ? null : jenisAutofill,
      cursorColor: WarnaCapify.coklatTua,
      style: const TextStyle(
        color: WarnaCapify.coklatGelap,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: petunjukIsian,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w300,
        ),
        prefixIcon: Icon(ikonDepan, color: WarnaCapify.coklatGelap),
        suffixIcon: tombolBelakang,
        filled: true,
        fillColor: WarnaCapify.putih,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: garisKolom,
        enabledBorder: garisKolom,
        focusedBorder: garisKolom.copyWith(
          borderSide: const BorderSide(color: WarnaCapify.krem, width: 2),
        ),
        errorStyle: const TextStyle(color: warnaPeringatan),
      ),
    );
  }
}

class TombolAuth extends StatelessWidget {
  final String teksTombol;
  final bool isSedangLoading;
  final VoidCallback onTekan;
  final bool isNonaktif;

  const TombolAuth({
    super.key,
    required this.teksTombol,
    required this.isSedangLoading,
    required this.onTekan,
    this.isNonaktif = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSedangLoading || isNonaktif ? null : onTekan,
        style: ElevatedButton.styleFrom(
          backgroundColor: WarnaCapify.krem,
          foregroundColor: WarnaCapify.coklatGelap,
          disabledBackgroundColor: WarnaCapify.krem.withValues(alpha: 0.6),
          disabledForegroundColor: WarnaCapify.coklatGelap.withValues(
            alpha: 0.7,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: isSedangLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: WarnaCapify.coklatGelap,
                ),
              )
            : Text(
                teksTombol,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class KotakPesanError extends StatelessWidget {
  final String pesan;
  final VoidCallback onTutup;

  const KotakPesanError({
    super.key,
    required this.pesan,
    required this.onTutup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: warnaPeringatan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warnaPeringatan.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline_rounded,
              color: warnaPeringatan,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                pesan,
                style: const TextStyle(
                  color: WarnaCapify.putih,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tutup pesan',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: WarnaCapify.krem,
            ),
            onPressed: onTutup,
          ),
        ],
      ),
    );
  }
}

class TombolLihatPassword extends StatelessWidget {
  final bool isTersembunyi;
  final VoidCallback onTekan;

  const TombolLihatPassword({
    super.key,
    required this.isTersembunyi,
    required this.onTekan,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isTersembunyi ? 'Tampilkan password' : 'Sembunyikan password',
      icon: Icon(
        isTersembunyi
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: WarnaCapify.coklatTua,
      ),
      onPressed: onTekan,
    );
  }
}

class KotakCentangAuth extends StatelessWidget {
  final bool isDicentang;
  final ValueChanged<bool?>? onUbah;
  final bool isAdaError;

  const KotakCentangAuth({
    super.key,
    required this.isDicentang,
    required this.onUbah,
    this.isAdaError = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: isDicentang,
        onChanged: onUbah,
        activeColor: WarnaCapify.krem,
        checkColor: WarnaCapify.coklatGelap,
        side: BorderSide(
          color: isAdaError ? warnaPeringatan : WarnaCapify.krem,
          width: 1.5,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class BarisPindahAuth extends StatelessWidget {
  final String teksPertanyaan;
  final String teksTombol;
  final VoidCallback? onTekan;

  const BarisPindahAuth({
    super.key,
    required this.teksPertanyaan,
    required this.teksTombol,
    required this.onTekan,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          teksPertanyaan,
          style: const TextStyle(
            color: WarnaCapify.putih,
            fontWeight: FontWeight.w300,
          ),
        ),
        TextButton(
          onPressed: onTekan,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 40),
          ),
          child: Text(
            teksTombol,
            style: const TextStyle(
              color: WarnaCapify.krem,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class IndikatorKekuatanPassword extends StatelessWidget {
  final int levelPassword;

  const IndikatorKekuatanPassword({super.key, required this.levelPassword});

  @override
  Widget build(BuildContext context) {
    int levelAman = levelPassword.clamp(0, 3);
    if (levelAman == 0) return const SizedBox.shrink();

    const List<String> namaLevel = ['', 'Lemah', 'Sedang', 'Kuat'];
    const List<Color> warnaLevel = [
      Colors.transparent,
      warnaPeringatan,
      Color(0xFFFFD180),
      Color(0xFFB9F6CA),
    ];
    Color warnaSekarang = warnaLevel[levelAman];

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
      child: Row(
        children: [
          for (int urutanBalok = 1; urutanBalok <= 3; urutanBalok++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: urutanBalok <= levelAman
                      ? warnaSekarang
                      : WarnaCapify.krem.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          SizedBox(
            width: 56,
            child: Text(
              namaLevel[levelAman],
              textAlign: TextAlign.end,
              style: TextStyle(
                color: warnaSekarang,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
