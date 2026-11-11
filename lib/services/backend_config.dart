import 'package:shared_preferences/shared_preferences.dart';

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

  BackendType type = BackendType.firebase;
  String supabaseUrl = '';
  String supabaseAnonKey = '';

  /// بريد مدير النظام (رئيس دائرة الاتصالات) — يمكن إضافة أكثر من بريد
  List<String> adminEmails = [
    'ferasnatof@gmail.com',
    'gfa437926@gmail.com',
  ];

  bool get isSupabase => type == BackendType.supabase;
  bool get isFirebase => type == BackendType.firebase;
  bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_keyBackend);
    type = t == 'supabase' ? BackendType.supabase : BackendType.firebase;
    supabaseUrl = prefs.getString(_keySupabaseUrl) ?? '';
    supabaseAnonKey = prefs.getString(_keySupabaseAnon) ?? '';
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
    if (e.isEmpty || adminEmails.map((x) => x.toLowerCase()).contains(e)) return;
    adminEmails = [...adminEmails, e];
    await save();
  }

  Future<void> removeAdminEmail(String email) async {
    adminEmails =
        adminEmails.where((x) => x.toLowerCase() != email.toLowerCase()).toList();
    await save();
  }

  bool isSystemAdmin(String? email) {
    if (email == null || email.isEmpty) return false;
    final e = email.toLowerCase();
    return adminEmails.any((a) => a.toLowerCase() == e);
  }
}
