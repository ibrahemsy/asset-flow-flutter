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
  final _newAdminEmailController = TextEditingController();
  final _targetProjectController = TextEditingController();
  bool _submittingHandover = false;
  String? _handoverMessage;

  @override
  void dispose() {
    _newAdminEmailController.dispose();
    _targetProjectController.dispose();
    super.dispose();
  }

  Future<void> _submitHandover(AppProvider app) async {
    final email = _newAdminEmailController.text.trim();
    final targetRef = _targetProjectController.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد طلب تسليم الإدارة'),
        content: Text(
          'سيُنشأ طلب تسليم للمدير $email إلى مشروع Supabase $targetRef. '
          'هذا الإجراء لا ينقل البيانات تلقائياً ولا يلغي صلاحية المدير الحالي.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إنشاء الطلب')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _submittingHandover = true; _handoverMessage = null; });
    final result = await app.requestAdminHandover(
      proposedAdminEmail: email,
      targetProjectRef: targetRef,
    );
    if (!mounted) return;
    setState(() {
      _submittingHandover = false;
      _handoverMessage = result == null
          ? 'لم يتم إنشاء الطلب. تحقق من صلاحياتك.'
          : result.startsWith('تعذر') || result.startsWith('هذه')
              ? result
              : 'تم إنشاء طلب التسليم بنجاح. رقم الطلب: $result — بانتظار قبول المدير الجديد.';
    });
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

          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_rounded, color: AppTheme.primary),
              title: const Text('قاعدة البيانات'),
              subtitle: const Text('Supabase فقط — المصادقة والبيانات والصلاحيات تُدار من مشروع Supabase المرتبط.'),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Expanded(child: Text('تسليم الإدارة إلى مشروع Supabase جديد',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'المدير الحالي هو من يحدد المشروع الوجهة. أدخل بريد المدير الجديد ومعرّف مشروعه (Project Ref) المكوّن من 20 حرفاً/رقماً. يمكن إدخال بريد المدير الجديد حتى لو لم يكن مسجلاً بعد في المشروع الحالي؛ تُستكمل مطابقة الحساب عند مرحلة القبول.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newAdminEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'بريد المدير الجديد',
                      hintText: 'admin@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _targetProjectController,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'معرّف مشروع Supabase الجديد',
                      hintText: 'xxxxxxxxxxxxxxxxxxxx',
                      prefixIcon: Icon(Icons.storage_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submittingHandover ? null : () => _submitHandover(app),
                      icon: _submittingHandover
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                      label: Text(_submittingHandover ? 'جارٍ إنشاء الطلب...' : 'إنشاء طلب تسليم الإدارة'),
                    ),
                  ),
                  if (_handoverMessage != null) ...[
                    const SizedBox(height: 10),
                    SelectableText(_handoverMessage!, style: const TextStyle(fontSize: 12)),
                  ],
                  const SizedBox(height: 6),
                  const Text(
                    'تنبيه أمني: إدخال المعرّف ينشئ طلباً موثقاً فقط. نقل الجداول والبيانات وملفات Storage وحسابات Auth يحتاج مرحلة ترحيل مستقلة والتحقق من الوجهة؛ لا تُحذف بيانات المصدر ولا تتغير صلاحيات المدير تلقائياً.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.45),
                  ),
                ],
              ),
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
                    'الجداول التشغيلية موجودة في مشروع Supabase المرتبط، '
                    'وتُطبق عليها سياسات Row Level Security.\\n\\n'
                    'الجداول الأساسية: devices, custody_cards, movements, '
                    'maintenance_tickets, phone_directory, telecom_networks, '
                    'audit_logs, pending_requests.\\n\\n'
                    'لا تُنشئ نسخاً مكررة من هذه الجداول يدوياً.',
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
                'الخلفية: Supabase\n'
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
