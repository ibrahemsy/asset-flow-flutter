import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';

class NetworkSwitchesScreen extends StatelessWidget {
  const NetworkSwitchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      body: app.networkSwitches.isEmpty
          ? const Center(child: Text('لا توجد سويتشات مسجلة بعد'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: app.networkSwitches.length,
              itemBuilder: (context, index) {
                final item = app.networkSwitches[index];
                final ports = item['portMappings'] is List ? item['portMappings'] as List : const [];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.hub_outlined)),
                    title: Text('${item['name'] ?? 'سويتش بدون اسم'}'),
                    subtitle: Text('الرقم: ${item['switchNumber'] ?? item['switch_number'] ?? '-'} • المنافذ: ${item['portsCount'] ?? item['ports_count'] ?? ports.length} • ${item['location'] ?? 'الموقع غير محدد'}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _showEditor(context, item);
                        if (value == 'delete') _confirmDelete(context, item);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                    onTap: () => _showDetails(context, item),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('إضافة سويتش'),
      ),
    );
  }

  static Future<void> _showEditor(BuildContext context, Map<String, dynamic>? existing) async {
    final formKey = GlobalKey<FormState>();
    final number = TextEditingController(text: '${existing?['switchNumber'] ?? existing?['switch_number'] ?? ''}');
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final model = TextEditingController(text: '${existing?['model'] ?? ''}');
    final location = TextEditingController(text: '${existing?['location'] ?? ''}');
    final ports = TextEditingController(text: '${existing?['portsCount'] ?? existing?['ports_count'] ?? '24'}');
    final notes = TextEditingController(text: '${existing?['notes'] ?? ''}');
    final mappings = (existing?['portMappings'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(existing == null ? 'تسجيل سويتش جديد' : 'تعديل السويتش'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(number, 'رقم السويتش', required: true),
                    _field(name, 'اسم السويتش', required: true),
                    _field(model, 'النوع / الموديل'),
                    _field(location, 'الموقع'),
                    _field(ports, 'عدد المنافذ', keyboard: TextInputType.number, positiveInteger: true),
                    _field(notes, 'ملاحظات', maxLines: 2),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: Text('توزيع المنافذ', style: Theme.of(context).textTheme.titleSmall)),
                    ...mappings.asMap().entries.map((entry) => _PortEditorRow(
                      mapping: entry.value,
                      onRemove: () => setDialogState(() => mappings.removeAt(entry.key)),
                    )),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setDialogState(() => mappings.add({'portNumber': '${mappings.length + 1}', 'pointNumber': '', 'officeLocation': '', 'connectedDevice': '', 'notes': ''})),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة ربط منفذ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
      ),
    );
    if (result == true && context.mounted) {
      final app = context.read<AppProvider>();
      final switchNumber = number.text.trim();
      final duplicate = app.networkSwitches.any((candidate) {
        final candidateId = '${candidate['id'] ?? ''}';
        final candidateNumber = '${candidate['switchNumber'] ?? candidate['switch_number'] ?? ''}'.trim();
        return candidateId != '${existing?['id'] ?? ''}' &&
            candidateNumber.isNotEmpty &&
            candidateNumber.toLowerCase() == switchNumber.toLowerCase();
      });
      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم السويتش مستخدم مسبقاً')),
        );
        number.dispose(); name.dispose(); model.dispose(); location.dispose(); ports.dispose(); notes.dispose();
        return;
      }
      final maxPorts = int.tryParse(ports.text.trim()) ?? 0;
      final portNumbers = mappings.map((m) => int.tryParse('${m['portNumber'] ?? ''}')).toList();
      final hasInvalidPorts = portNumbers.any((p) => p == null || p < 1 || p > maxPorts) ||
          portNumbers.whereType<int>().toSet().length != portNumbers.length;
      if (hasInvalidPorts) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تأكد من أن أرقام المنافذ بين 1 و$maxPorts وغير مكررة')),
        );
        number.dispose(); name.dispose(); model.dispose(); location.dispose(); ports.dispose(); notes.dispose();
        return;
      }
      final item = <String, dynamic>{
        'id': existing?['id'] ?? const Uuid().v4(),
        'switchNumber': number.text.trim(),
        'name': name.text.trim(),
        'model': model.text.trim(),
        'location': location.text.trim(),
        'portsCount': ports.text.trim(),
        'status': existing?['status'] ?? 'active',
        'notes': notes.text.trim(),
        'portMappings': mappings,
      };
      final error = await context.read<AppProvider>().saveNetworkSwitch(item);
      if (context.mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
    number.dispose(); name.dispose(); model.dispose(); location.dispose(); ports.dispose(); notes.dispose();
  }

  static Widget _field(TextEditingController controller, String label, {bool required = false, bool positiveInteger = false, TextInputType? keyboard, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) return 'هذا الحقل مطلوب';
            if (positiveInteger) {
              final parsed = int.tryParse(value?.trim() ?? '');
              if (parsed == null || parsed < 1) return 'أدخل عدداً صحيحاً أكبر من صفر';
            }
            return null;
          },
        ),
      );

  static Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف السويتش؟'),
        content: Text('سيتم إرسال طلب حذف ${item['name']} للاعتماد أو تنفيذه حسب صلاحيتك.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('تأكيد الحذف')),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      final error = await context.read<AppProvider>().deleteNetworkSwitch('${item['id']}', '${item['name']}');
      if (context.mounted && error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  static void _showDetails(BuildContext context, Map<String, dynamic> item) {
    final mappings = item['portMappings'] is List ? item['portMappings'] as List : const [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['name']}', style: Theme.of(context).textTheme.titleLarge),
                Text('رقم السويتش: ${item['switchNumber'] ?? item['switch_number'] ?? '-'}'),
                Text('الموديل: ${item['model'] ?? '-'} • الموقع: ${item['location'] ?? '-'}'),
                const Divider(),
                const Text('المنافذ المرتبطة'),
                if (mappings.isEmpty) const Text('لم تتم إضافة ربط للمنافذ'),
                ...mappings.map((raw) {
                  final port = Map<String, dynamic>.from(raw as Map);
                  return ListTile(
                    dense: true,
                    title: Text('منفذ ${port['portNumber'] ?? '-'} • نقطة ${port['pointNumber'] ?? '-'}'),
                    subtitle: Text('${port['officeLocation'] ?? ''} • ${port['connectedDevice'] ?? ''}'),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortEditorRow extends StatelessWidget {
  final Map<String, dynamic> mapping;
  final VoidCallback onRemove;
  const _PortEditorRow({required this.mapping, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextFormField(
                initialValue: '${mapping['portNumber'] ?? ''}',
                decoration: const InputDecoration(labelText: 'رقم المنفذ'),
                validator: (value) { final n = int.tryParse(value?.trim() ?? ''); return n == null || n < 1 ? 'رقم منفذ صحيح مطلوب' : null; },
                onChanged: (value) => mapping['portNumber'] = value,
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                initialValue: '${mapping['pointNumber'] ?? ''}',
                decoration: const InputDecoration(labelText: 'رقم النقطة'),
                onChanged: (value) => mapping['pointNumber'] = value,
              )),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
            ]),
            TextFormField(
              initialValue: '${mapping['officeLocation'] ?? ''}',
              decoration: const InputDecoration(labelText: 'المكتب / الموقع'),
              onChanged: (value) => mapping['officeLocation'] = value,
            ),
            Consumer<AppProvider>(
              builder: (context, app, _) {
                final deviceIds = app.devices.map((device) => device.id).toSet();
                final selected = mapping['deviceId']?.toString();
                return DropdownButtonFormField<String>(
                  value: selected != null && deviceIds.contains(selected) ? selected : null,
                  decoration: const InputDecoration(labelText: 'ربط بجهاز مسجل في الأصول'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('بدون جهاز مرتبط')),
                    ...app.devices.map((device) => DropdownMenuItem<String>(
                      value: device.id,
                      child: Text('${device.name} — ${device.serialNumber}'),
                    )),
                  ],
                  onChanged: (value) => mapping['deviceId'] = value,
                );
              },
            ),
            TextFormField(
              initialValue: '${mapping['connectedDevice'] ?? ''}',
              decoration: const InputDecoration(labelText: 'وصف الجهاز / ملاحظة'),
              onChanged: (value) => mapping['connectedDevice'] = value,
            ),
          ],
        ),
      ),
    );
  }
}
