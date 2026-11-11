import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_icons.dart';
import '../models/models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _busy = false;
  String? _status;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _status = 'خطأ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              const Row(
                children: [
                  Icon(AppIcons.reports, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('التقارير والتصدير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

              // إحصائيات
              _ReportCard(
                title: 'ملخص الأجهزة',
                icon: AppIcons.devices,
                color: AppTheme.primary,
                rows: [
                  _ReportRow('الإجمالي', '${app.devices.length}'),
                  _ReportRow('مستودع', '${app.devices.where((d) => d.status == DeviceStatus.inWarehouse).length}'),
                  _ReportRow('مسلّمة', '${app.devices.where((d) => d.status == DeviceStatus.assignedEmployee || d.status == DeviceStatus.assignedDepartment).length}'),
                  _ReportRow('صيانة', '${app.devices.where((d) => d.status == DeviceStatus.inMaintenance).length}'),
                ],
              ),
              _ReportCard(
                title: 'العهدة والصيانة',
                icon: AppIcons.custody,
                color: const Color(0xFF7C3AED),
                rows: [
                  _ReportRow('بطاقات عهدة', '${app.custodyCards.length}'),
                  _ReportRow('بلاغات مفتوحة', '${app.tickets.where((t) => t.status != TicketStatus.closed && t.status != TicketStatus.repaired).length}'),
                  _ReportRow('سندات حركة', '${app.movements.length}'),
                ],
              ),

              const SizedBox(height: 8),
              const Text('تصدير Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.table_chart_rounded,
                color: const Color(0xFF16A34A),
                title: 'تصدير الأجهزة',
                subtitle: 'ملف Excel بالأجهزة الحالية',
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          final path = await app.exportDevicesExcel();
                          setState(() => _status = path != null && !path.startsWith('خطأ') ? 'تم التصدير: $path' : path);
                          if (mounted && path != null && !path.startsWith('خطأ')) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ/مشاركة الملف')));
                          }
                        }),
              ),
              _ActionTile(
                icon: Icons.badge_rounded,
                color: const Color(0xFF7C3AED),
                title: 'تصدير بطاقات العهدة',
                subtitle: 'Excel بالعهدة والمواد',
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          final path = await app.exportCustodyExcel();
                          setState(() => _status = path);
                        }),
              ),
              _ActionTile(
                icon: Icons.summarize_rounded,
                color: AppTheme.primary,
                title: 'تقرير Excel شامل',
                subtitle: 'أجهزة + عهدة + حركات + صيانة + هواتف',
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          final path = await app.exportFullExcel();
                          setState(() => _status = path);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(path != null && !path.startsWith('خطأ') ? 'تم إنشاء التقرير الشامل' : path ?? 'فشل')),
                            );
                          }
                        }),
              ),

              const SizedBox(height: 16),
              const Text('Google Sheets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              const Text(
                'يتطلب تسجيل الدخول بحساب Google والموافقة على صلاحية جداول البيانات.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.grid_on_rounded,
                color: const Color(0xFF0F9D58),
                title: 'تصدير الجرد إلى Google Sheets',
                subtitle: 'إنشاء جدول جديد: أجهزة + عهدة',
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          final result = await app.exportToGoogleSheets();
                          setState(() => _status = 'تم إنشاء الجدول');
                          if (mounted) {
                            await _showSheetsSuccess(context, result.spreadsheetUrl);
                          }
                        }),
              ),
              _ActionTile(
                icon: Icons.cloud_upload_rounded,
                color: const Color(0xFF4285F4),
                title: 'تقرير شامل على Google Sheets',
                subtitle: 'أجهزة + عهدة + حركات + صيانة',
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          final result = await app.exportFullToGoogleSheets();
                          setState(() => _status = 'تم إنشاء التقرير على Sheets');
                          if (mounted) {
                            await _showSheetsSuccess(context, result.spreadsheetUrl);
                          }
                        }),
              ),

              const SizedBox(height: 16),
              const Text('استيراد من Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.upload_file_rounded,
                color: AppTheme.accent,
                title: 'استيراد أجهزة من Excel',
                subtitle: 'اختيار ملف .xlsx',
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          final res = await app.importDevicesExcel();
                          setState(() => _status = res.message);
                          if (res.success && res.items.isNotEmpty) {
                            for (final d in res.items) {
                              await app.saveDevice(d);
                            }
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
                          }
                        }),
              ),
              _ActionTile(
                icon: Icons.upload_file_rounded,
                color: const Color(0xFF7C3AED),
                title: 'استيراد بطاقات عهدة من Excel',
                subtitle: 'اختيار ملف .xlsx',
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          final res = await app.importCustodyExcel();
                          setState(() => _status = res.message);
                          if (res.success && res.items.isNotEmpty) {
                            for (final c in res.items) {
                              await app.saveCustodyCard(c);
                            }
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
                          }
                        }),
              ),

              if (_status != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Text(_status!, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('جارٍ التنفيذ...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showSheetsSuccess(BuildContext context, String url) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success),
            SizedBox(width: 8),
            Text('تم التصدير'),
          ],
        ),
        content: const Text('تم إنشاء جدول Google Sheets بنجاح. يمكنك فتحه الآن في المتصفح.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('فتح الجدول'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SectionIcon(icon: icon, color: color, size: 42),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_ReportRow> rows;

  const _ReportCard({required this.title, required this.icon, required this.color, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Divider(height: 16),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      Text(r.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ReportRow {
  final String label;
  final String value;
  const _ReportRow(this.label, this.value);
}
