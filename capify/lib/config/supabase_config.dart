import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://yydinenglkryhwfeiuzi.supabase.co';
  static const String publishableKey =
      'sb_publishable_mLjA0m1FAg9JNMrMIK-O4w_nOHdb34M';

  static bool get isSudahDiisi {
    return url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;
  }

  static Future<bool> siapkanSupabase() async {
    if (!isSudahDiisi) return false;

    try {
      await Supabase.initialize(url: url, publishableKey: publishableKey);
      return true;
    } catch (_) {
      return false;
    }
  }
}
