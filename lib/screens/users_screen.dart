import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_icons.dart';

/// شاشة الإدارة — متاحة فقط لمدير النظام (رئيس دائرة الاتصالات)
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {

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

          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_rounded, color: AppTheme.primary),
              title: const Text('قاعدة البيانات'),
              subtitle: const Text('Supabase فقط — المصادقة والبيانات والصلاحيات تُدار من مشروع Supabase المرتبط.'),
            ),
          ),

          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings_rounded, color: AppTheme.success),
              title: Text('إدارة المديرين والصلاحيات'),
              subtitle: Text('مصدر الصلاحيات هو private.admin_assignments داخل قاعدة البيانات، ولا يعتمد التطبيق على قائمة بريد محلية.'),
            ),
          ),

          const SizedBox(height: 20),
          // ---- جداول Supabase ----
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

}
