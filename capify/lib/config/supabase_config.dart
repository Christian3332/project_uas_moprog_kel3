import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = '';
  static const String publishableKey = '';

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
