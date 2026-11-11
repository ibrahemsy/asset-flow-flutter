import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/backend_config.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_icons.dart';

/// شاشة الإدارة — متاحة فقط لمدير النظام (رئيس دائرة الاتصالات)
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _cfg = BackendConfig();
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _busy = false;
  String? _msg;
  bool _msgErr = false;

  @override
  void initState() {
    super.initState();
    _cfg.load().then((_) {
      _urlCtrl.text = _cfg.supabaseUrl;
      _keyCtrl.text = _cfg.supabaseAnonKey;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    if (!app.isSystemAdmin) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('مدير النظام فقط', style: TextStyle(color: AppTheme.textSecondary)),
            Text('(رئيس دائرة الاتصالات)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            const SectionIcon(icon: Icons.admin_panel_settings_rounded, color: AppTheme.primary, size: 44),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('إدارة النظام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(app.currentUser?.email ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ])),
            const IconChip(icon: Icons.verified_rounded, label: 'مدير النظام', color: AppTheme.success),
          ]),
          const SizedBox(height: 20),

          // ---- الخلفية ----
          const Text('خلفية البيانات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SegmentedButton<BackendType>(
                  segments: const [
                    ButtonSegment(value: BackendType.firebase, label: Text('Firebase'), icon: Icon(Icons.local_fire_department_rounded, size: 18)),
                    ButtonSegment(value: BackendType.supabase, label: Text('Supabase'), icon: Icon(Icons.storage_rounded, size: 18)),
                  ],
                  selected: {_cfg.type},
                  onSelectionChanged: (s) async {
                    setState(() => _busy = true);
                    await _cfg.setBackend(s.first);
                    setState(() {
                      _busy = false;
                      _msg = 'تم تغيير الخلفية إلى ${s.first == BackendType.supabase ? "Supabase" : "Firebase"}. أعد تشغيل التطبيق لتطبيق التغيير بالكامل.';
                      _msgErr = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_cfg.isSupabase) ...[
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Supabase URL',
                      hintText: 'https://xxxx.supabase.co',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _keyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Anon Key',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : () async {
                      setState(() => _busy = true);
                      try {
                        await _cfg.setSupabaseCredentials(url: _urlCtrl.text, anonKey: _keyCtrl.text);
                        await SupabaseService.initialize();
                        setState(() {
                          _msg = 'تم حفظ إعدادات Supabase والتهيئة بنجاح';
                          _msgErr = false;
                        });
                      } catch (e) {
                        setState(() {
                          _msg = 'خطأ: $e';
                          _msgErr = true;
                        });
                      } finally {
                        setState(() => _busy = false);
                      }
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('حفظ وتهيئة Supabase'),
                  ),
                ] else
                  const Text(
                    'الوضع الحالي: Firebase (Auth + Firestore)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
              ]),
            ),
          ),

          if (_msg != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _msgErr ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_msg!, style: TextStyle(color: _msgErr ? AppTheme.danger : const Color(0xFF065F46), fontSize: 13)),
            ),
          ],

          const SizedBox(height: 20),
          // ---- مديرو النظام ----
          Row(children: [
            const Text('مديرو النظام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addAdmin(context),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('إضافة'),
            ),
          ]),
          const SizedBox(height: 4),
          const Text(
            'رئيس دائرة الاتصالات = مدير النظام (اعتماد الطلبات + الكتابة المباشرة + الإعدادات)',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          ..._cfg.adminEmails.map((email) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: const SectionIcon(icon: Icons.verified_rounded, color: AppTheme.success, size: 36),
              title: Text(email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: const Text('مدير نظام / رئيس دائرة', style: TextStyle(fontSize: 11)),
              trailing: _cfg.adminEmails.length > 1
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger, size: 20),
                      onPressed: () async {
                        await _cfg.removeAdminEmail(email);
                        setState(() {});
                      },
                    )
                  : null,
            ),
          )),

          const SizedBox(height: 20),
          // ---- جداول Supabase ----
          if (_cfg.isSupabase)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.table_chart_rounded, color: AppTheme.primary),
                title: const Text('جداول Supabase المطلوبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: const [
                  Text(
                    'أنشئ الجداول التالية في SQL Editor:\n\n'
                    '• devices\n'
                    '• custody_cards\n'
                    '• movements\n'
                    '• maintenance_tickets\n'
                    '• phone_directory\n'
                    '• telecom_networks\n'
                    '• audit_logs\n'
                    '• pending_requests\n\n'
                    'كل جدول يحتاج عمود id (text PK) وباقي الحقول حسب النماذج.\n'
                    'فعّل Row Level Security حسب الحاجة.\n'
                    'مدير النظام يعتمد الطلبات من جدول pending_requests.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primary),
              title: const Text('معلومات'),
              subtitle: Text(
                'الدور: مدير النظام\n'
                'الخلفية: ${_cfg.isSupabase ? "Supabase" : "Firebase"}\n'
                'القسم: ${app.departmentName}',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _addAdmin(BuildContext context) async {
    final ctrl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة مدير نظام'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'البريد الإلكتروني', hintText: 'admin@example.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('إضافة')),
        ],
      ),
    );
    if (email != null && email.contains('@')) {
      await _cfg.addAdminEmail(email);
      setState(() {});
    }
  }
}
