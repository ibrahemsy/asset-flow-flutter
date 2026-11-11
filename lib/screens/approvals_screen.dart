import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    if (!app.isHeadOfDept) {
      return const Center(
        child: Text('هذه الصفحة متاحة فقط لرئيس الدائرة', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final pending = app.pendingRequests.where((r) => r.status == 'pending').toList();
    final reviewed = app.pendingRequests.where((r) => r.status != 'pending').toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppTheme.primary,
            tabs: [
              Tab(text: 'بانتظار الاعتماد'),
              Tab(text: 'تمت المراجعة'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                pending.isEmpty
                    ? const Center(child: Text('لا توجد طلبات معلقة'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: pending.length,
                        itemBuilder: (_, i) => _RequestCard(req: pending[i], isPending: true),
                      ),
                reviewed.isEmpty
                    ? const Center(child: Text('لا توجد طلبات مراجعة'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: reviewed.length,
                        itemBuilder: (_, i) => _RequestCard(req: reviewed[i], isPending: false),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PendingRequest req;
  final bool isPending;

  const _RequestCard({required this.req, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(req.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (!isPending)
                  Chip(
                    label: Text(req.status == 'approved' ? 'معتمد' : 'مرفوض', style: const TextStyle(fontSize: 11)),
                    backgroundColor: req.status == 'approved'
                        ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.danger.withOpacity(0.15),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(req.details, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              'من: ${req.requesterName} (${req.requesterEmail})',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Text(
              'بتاريخ: ${req.createdAt.split('T').first}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await app.approveRequest(req);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم اعتماد الطلب'), backgroundColor: AppTheme.success),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('اعتماد'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final reason = await _askReason(context);
                        if (reason != null) {
                          await app.rejectRequest(req.id, reason);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم رفض الطلب'), backgroundColor: AppTheme.danger),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.close, size: 18, color: AppTheme.danger),
                      label: const Text('رفض', style: TextStyle(color: AppTheme.danger)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _askReason(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'أدخل سبب الرفض'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim().isEmpty ? 'بدون سبب' : ctrl.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}
