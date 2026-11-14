import 'package:shared_preferences/shared_preferences.dart';

/// نوع الخلفية المستخدمة
enum BackendType { supabase }

/// إعدادات الربط: Supabase فقط
class BackendConfig {
  static final BackendConfig _instance = BackendConfig._internal();
  factory BackendConfig() => _instance;
  BackendConfig._internal();

  static const _keyBackend = 'backend_type';
  static const _keySupabaseUrl = 'supabase_url';
  static const _keySupabaseAnon = 'supabase_anon_key';

  BackendType type = BackendType.supabase;
  String supabaseUrl = '';
  String supabaseAnonKey = '';

  bool get isSupabase => true;
  bool get isFirebase => false;
  bool get supabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_keyBackend);
    type = BackendType.supabase;
    supabaseUrl = prefs.getString(_keySupabaseUrl) ?? '';
    supabaseAnonKey = prefs.getString(_keySupabaseAnon) ?? '';
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyBackend,
      'supabase',
    );
    await prefs.setString(_keySupabaseUrl, supabaseUrl);
    await prefs.setString(_keySupabaseAnon, supabaseAnonKey);
  }

  Future<void> setBackend(BackendType t) async {
    type = t;
    await save();
  }

  Future<void> setSupabaseCredentials({
    required String url,
    required String anonKey,
  }) async {
    supabaseUrl = url.trim();
    supabaseAnonKey = anonKey.trim();
    await save();
  }

}
