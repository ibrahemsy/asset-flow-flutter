import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_secrets.dart';

/// نوع الخلفية المستخدمة
enum BackendType { firebase, supabase }

/// إعدادات الربط: Firebase أو Supabase
class BackendConfig {
  static final BackendConfig _instance = BackendConfig._internal();
  factory BackendConfig() => _instance;
  BackendConfig._internal();

  static const _keyBackend = 'backend_type';
  static const _keySupabaseUrl = 'supabase_url';
  static const _keySupabaseAnon = 'supabase_anon_key';
  static const _keyAdminEmails = 'admin_emails';

  /// الافتراضي: Supabase
  BackendType type = BackendType.supabase;
  String supabaseUrl = SupabaseSecrets.url;
  String supabaseAnonKey = SupabaseSecrets.anonKey;

  /// بريد مدير النظام (رئيس دائرة الاتصالات)
  List<String> adminEmails = [
    'baselformobile@gmail.com',
  ];

  bool get isSupabase => type == BackendType.supabase;
  bool get isFirebase => type == BackendType.firebase;
  bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_keyBackend);
    // إن لم يختر المستخدم سابقاً → Supabase
    if (t == 'firebase') {
      type = BackendType.firebase;
    } else {
      type = BackendType.supabase;
    }
    supabaseUrl = prefs.getString(_keySupabaseUrl) ?? SupabaseSecrets.url;
    supabaseAnonKey =
        prefs.getString(_keySupabaseAnon) ?? SupabaseSecrets.anonKey;
    final admins = prefs.getStringList(_keyAdminEmails);
    if (admins != null && admins.isNotEmpty) {
      adminEmails = admins;
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyBackend,
      type == BackendType.supabase ? 'supabase' : 'firebase',
    );
    await prefs.setString(_keySupabaseUrl, supabaseUrl);
    await prefs.setString(_keySupabaseAnon, supabaseAnonKey);
    await prefs.setStringList(_keyAdminEmails, adminEmails);
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

  Future<void> addAdminEmail(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || adminEmails.map((x) => x.toLowerCase()).contains(e)) {
      return;
    }
    adminEmails = [...adminEmails, e];
    await save();
  }

  Future<void> removeAdminEmail(String email) async {
    adminEmails = adminEmails
        .where((x) => x.toLowerCase() != email.toLowerCase())
        .toList();
    await save();
  }

  bool isSystemAdmin(String? email) {
    if (email == null || email.isEmpty) return false;
    final e = email.toLowerCase();
    return adminEmails.any((a) => a.toLowerCase() == e);
  }
}
