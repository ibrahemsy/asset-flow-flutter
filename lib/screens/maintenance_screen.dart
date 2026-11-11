import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final list = app.tickets;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: list.isEmpty
          ? const Center(child: Text('لا توجد بلاغات صيانة', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final t = list[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _priorityColor(t.priority).withOpacity(0.15),
                      child: Icon(Icons.build, color: _priorityColor(t.priority)),
                    ),
                    title: Text(t.deviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${t.faultDescription}\n${t.status.labelAr} • ${t.reportDate}'),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(t.priority.labelAr, style: const TextStyle(fontSize: 11)),
                      backgroundColor: _priorityColor(t.priority).withOpacity(0.12),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, app),
        icon: const Icon(Icons.add),
        label: const Text('بلاغ صيانة جديد'),
      ),
    );
  }

  Color _priorityColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.critical: return AppTheme.danger;
      case TicketPriority.high: return AppTheme.warning;
      case TicketPriority.normal: return AppTheme.primary;
      case TicketPriority.low: return AppTheme.textSecondary;
    }
  }

  void _showForm(BuildContext context, AppProvider app) {
    final ticketNoCtrl = TextEditingController();
    final deviceNameCtrl = TextEditingController();
    final faultCtrl = TextEditingController();
    final stationCtrl = TextEditingController();
    final techCtrl = TextEditingController();
    TicketPriority priority = TicketPriority.normal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('بلاغ صيانة جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextField(controller: ticketNoCtrl, decoration: const InputDecoration(labelText: 'رقم البلاغ *')),
                  const SizedBox(height: 10),
                  TextField(controller: deviceNameCtrl, decoration: const InputDecoration(labelText: 'اسم / نوع الجهاز *')),
                  const SizedBox(height: 10),
                  TextField(controller: faultCtrl, decoration: const InputDecoration(labelText: 'وصف العطل *'), maxLines: 3),
                  const SizedBox(height: 10),
                  TextField(controller: stationCtrl, decoration: const InputDecoration(labelText: 'القسم / المكتب')),
                  const SizedBox(height: 10),
                  TextField(controller: techCtrl, decoration: const InputDecoration(labelText: 'الفني المكلف')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<TicketPriority>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'الأولوية'),
                    items: TicketPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.labelAr))).toList(),
                    onChanged: (v) => setModal(() => priority = v!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (ticketNoCtrl.text.trim().isEmpty || deviceNameCtrl.text.trim().isEmpty || faultCtrl.text.trim().isEmpty) return;
                      final now = DateTime.now().toIso8601String();
                      final t = MaintenanceTicket(
                        id: const Uuid().v4(),
                        ticketNumber: ticketNoCtrl.text.trim(),
                        deviceName: deviceNameCtrl.text.trim(),
                        faultDescription: faultCtrl.text.trim(),
                        stationOrDept: stationCtrl.text.trim(),
                        reportDate: now.split('T').first,
                        priority: priority,
                        assignedTech: techCtrl.text.trim(),
                        actionsTaken: '',
                        sparePartsUsed: '',
                        status: TicketStatus.newTicket,
                        createdAt: now,
                      );
                      final msg = await app.saveTicket(t);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'تم الحفظ')));
                      }
                    },
                    child: const Text('تسجيل البلاغ'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
