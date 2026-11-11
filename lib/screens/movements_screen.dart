import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class MovementsScreen extends StatelessWidget {
  const MovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final list = app.movements;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: list.isEmpty
          ? const Center(child: Text('لا توجد حركات', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final m = list[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accent.withOpacity(0.15),
                      child: const Icon(Icons.swap_horiz, color: AppTheme.accent),
                    ),
                    title: Text(m.deviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${m.type.labelAr}\nمن: ${m.fromEntity} → إلى: ${m.toEntity}'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(m.referenceNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(m.date, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, app),
        icon: const Icon(Icons.add),
        label: const Text('سند حركة جديد'),
      ),
    );
  }

  void _showForm(BuildContext context, AppProvider app) {
    final refCtrl = TextEditingController();
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    MovementType type = MovementType.handover;
    Device? selectedDevice;

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
                  const Text('سند حركة جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'رقم السند *')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<MovementType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'نوع الحركة'),
                    items: MovementType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.labelAr))).toList(),
                    onChanged: (v) => setModal(() => type = v!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Device>(
                    value: selectedDevice,
                    decoration: const InputDecoration(labelText: 'الجهاز'),
                    items: app.devices.map((d) => DropdownMenuItem(value: d, child: Text('${d.name} (${d.serialNumber})'))).toList(),
                    onChanged: (v) => setModal(() => selectedDevice = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'من (المسلّم)')),
                  const SizedBox(height: 10),
                  TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'إلى (المستلم)')),
                  const SizedBox(height: 10),
                  TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'السبب'), maxLines: 2),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (refCtrl.text.trim().isEmpty || selectedDevice == null) return;
                      final now = DateTime.now().toIso8601String();
                      final m = Movement(
                        id: const Uuid().v4(),
                        referenceNumber: refCtrl.text.trim(),
                        type: type,
                        deviceId: selectedDevice!.id,
                        deviceName: selectedDevice!.name,
                        serialNumber: selectedDevice!.serialNumber,
                        barcode: selectedDevice!.barcode,
                        fromEntity: fromCtrl.text.trim(),
                        toEntity: toCtrl.text.trim(),
                        executorName: app.currentUser?.displayName ?? '',
                        date: now.split('T').first,
                        reason: reasonCtrl.text.trim(),
                        createdAt: now,
                      );
                      final msg = await app.saveMovement(m);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'تم الحفظ')));
                      }
                    },
                    child: const Text('حفظ السند'),
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
