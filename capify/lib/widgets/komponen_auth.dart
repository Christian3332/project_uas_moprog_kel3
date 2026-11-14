import 'package:flutter/material.dart';

import '../utils/warna_capify.dart';

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
      autofillHints: jenisAutofill,
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
        errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
      ),
    );
  }
}

class TombolAuth extends StatelessWidget {
  final String teksTombol;
  final bool isSedangLoading;
  final VoidCallback onTekan;

  const TombolAuth({
    super.key,
    required this.teksTombol,
    required this.isSedangLoading,
    required this.onTekan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSedangLoading ? null : onTekan,
        style: ElevatedButton.styleFrom(
          backgroundColor: WarnaCapify.krem,
          foregroundColor: WarnaCapify.coklatGelap,
          disabledBackgroundColor: WarnaCapify.krem.withValues(alpha: 0.6),
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

class PemisahAtau extends StatelessWidget {
  final String teksTengah;

  const PemisahAtau({super.key, required this.teksTengah});

  @override
  Widget build(BuildContext context) {
    Color warnaGaris = WarnaCapify.krem.withValues(alpha: 0.3);

    return Row(
      children: [
        Expanded(child: Divider(color: warnaGaris)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            teksTengah,
            style: TextStyle(
              color: WarnaCapify.krem.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        Expanded(child: Divider(color: warnaGaris)),
      ],
    );
  }
}

class TombolSosialAuth extends StatelessWidget {
  final IconData ikonLayanan;
  final String namaLayanan;
  final VoidCallback? onTekan;

  const TombolSosialAuth({
    super.key,
    required this.ikonLayanan,
    required this.namaLayanan,
    required this.onTekan,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTekan,
      icon: Icon(ikonLayanan, size: 26),
      label: Text(
        namaLayanan,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: WarnaCapify.putih,
        backgroundColor: WarnaCapify.hitam.withValues(alpha: 0.25),
        side: BorderSide(color: WarnaCapify.krem.withValues(alpha: 0.5)),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
