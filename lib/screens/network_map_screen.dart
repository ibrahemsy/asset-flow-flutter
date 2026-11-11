import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

class NetworkMapScreen extends StatelessWidget {
  const NetworkMapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final computers = app.devices.where((d) => d.category == DeviceCategory.desktop || d.category == DeviceCategory.laptop).toList();
    final internal = computers.where((d) => d.networkConnection == 'internalServer').length;
    final external = computers.where((d) => d.networkConnection == 'externalInternet').length;
    final unset = computers.where((d) => d.networkConnection == null || d.networkConnection!.isEmpty).length;
    return Scaffold(backgroundColor: const Color(0xFF0F172A),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        const Text('مخطط الشبكة والسويتشات', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _stat('السويتشات', app.networkSwitches.length, Colors.cyanAccent),
          _stat('سيرفر داخلي', internal, Colors.lightGreenAccent),
          _stat('إنترنت خارجي', external, Colors.orangeAccent),
          _stat('غير محدد', unset, Colors.amberAccent),
        ]),
        const SizedBox(height: 14),
        Row(children: [const Expanded(child: Text('سجل السويتشات المستقل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          FilledButton.icon(onPressed: () => _editSwitch(context), icon: const Icon(Icons.add), label: const Text('إضافة سويتش'))]),
        const SizedBox(height: 8),
        if (app.networkSwitches.isEmpty) const Text('لم تتم إضافة سويتشات بعد.', style: TextStyle(color: Colors.white54))
        else ...app.networkSwitches.map((sw) => _switchCard(context, sw, app)),
        const SizedBox(height: 16),
        const Text('أجهزة الحواسيب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...computers.map((d) => Card(color: const Color(0xFF1E293B), child: ListTile(
          leading: const Icon(Icons.desktop_windows, color: Colors.cyanAccent),
          title: Text(d.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text('${d.networkConnection ?? 'لم يحدد المسار'} • ${d.switchNumber ?? 'لم يربط بسويتش'} • المنفذ ${d.switchPortNumber ?? '—'}', style: const TextStyle(color: Colors.white60)),
        ))),
        const SizedBox(height: 12),
        const Text('ملاحظة: رقم النقطة الشبكية يمكن تركه فارغاً وإضافته لاحقاً إلى منفذ السويتش. المخطط يعرض البيانات المسجلة ولا يؤكد حالة الاتصال الحية.', style: TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }

  Widget _stat(String label, int value, Color color) => Container(padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(.3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10))]));

  Widget _switchCard(BuildContext context, NetworkSwitch sw, AppProvider app) {
    final used = sw.ports.where((p) => (p.connectedDeviceId ?? '').isNotEmpty).length;
    final pointsMissing = sw.ports.where((p) => p.pointNumber == null || p.pointNumber!.trim().isEmpty).length;
    return Card(color: const Color(0xFF1E293B), margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(leading: const Icon(Icons.device_hub, color: Colors.cyanAccent),
        title: Text('السويتش ${sw.switchNumber} — ${sw.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('${sw.floor} • ${sw.portCount} منفذ • مستخدم $used • نقاط غير معرفة $pointsMissing', style: const TextStyle(color: Colors.white60, fontSize: 11)),
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
            Expanded(child: Text('الموقع: ${sw.location} | ${sw.connectionType == 'internalServer' ? 'سيرفر داخلي' : 'إنترنت خارجي'}', style: const TextStyle(color: Colors.white54, fontSize: 11))),
            TextButton.icon(onPressed: () => _editSwitch(context, existing: sw), icon: const Icon(Icons.edit, size: 16), label: const Text('تعديل')),
          ])),
          ...List.generate(sw.portCount, (index) {
            final number = '${index + 1}';
            final port = sw.ports.where((p) => p.portNumber == number).firstOrNull;
            final device = app.devices.where((d) => d.switchId == sw.id && d.switchPortNumber == number).firstOrNull;
            return ListTile(dense: true, leading: Icon(device == null ? Icons.radio_button_unchecked : Icons.link, color: device == null ? Colors.white38 : Colors.lightGreenAccent),
              title: Text('منفذ $number', style: const TextStyle(color: Colors.white)),
              subtitle: Text('النقطة: ${port?.pointNumber?.isNotEmpty == true ? port!.pointNumber : 'غير محددة'} • ${device?.name ?? 'غير مربوط بحاسب'}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              trailing: IconButton(tooltip: 'إضافة أو تعديل رقم النقطة', icon: const Icon(Icons.edit_note, color: Colors.cyanAccent), onPressed: () => _editPoint(context, sw, number, port)),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _editSwitch(BuildContext context, {NetworkSwitch? existing}) async {
    final app = context.read<AppProvider>();
    final number = TextEditingController(text: existing?.switchNumber);
    final name = TextEditingController(text: existing?.name);
    final location = TextEditingController(text: existing?.location);
    final count = TextEditingController(text: existing?.portCount.toString() ?? '24');
    String floor = existing?.floor ?? 'الأرضي';
    String path = existing?.connectionType ?? 'internalServer';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      title: Text(existing == null ? 'إضافة سويتش' : 'تعديل السويتش'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: number, decoration: const InputDecoration(labelText: 'رقم السويتش *')),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم / موديل السويتش')),
        TextField(controller: location, decoration: const InputDecoration(labelText: 'الموقع التفصيلي')),
        TextField(controller: count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد المنافذ *')),
        DropdownButtonFormField<String>(value: floor, decoration: const InputDecoration(labelText: 'الطابق'), items: const ['القبو','الأرضي','الأول','الثاني','الثالث','الرابع','الخامس','السادس','السابع','الثامن','التاسع','العاشر'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(), onChanged:(v)=>setState(()=>floor=v ?? floor)),
        DropdownButtonFormField<String>(value: path, decoration: const InputDecoration(labelText: 'مسار الشبكة'), items: const [DropdownMenuItem(value:'internalServer',child:Text('سيرفر داخلي')),DropdownMenuItem(value:'externalInternet',child:Text('إنترنت خارجي'))], onChanged:(v)=>setState(()=>path=v ?? path)),
      ])),
      actions: [TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')), FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))],
    )));
    if (ok != true) return;
    final n = int.tryParse(count.text.trim());
    if (number.text.trim().isEmpty || n == null || n < 1 || n > 96) { _message(context, 'أدخل رقم سويتش وعدداً صحيحاً للمنافذ بين 1 و96'); return; }
    if (app.networkSwitches.any((s) => s.switchNumber.toLowerCase() == number.text.trim().toLowerCase() && s.id != existing?.id)) { _message(context, 'رقم السويتش مستخدم مسبقاً'); return; }
    if (existing != null && (existing.ports.any((p) => (int.tryParse(p.portNumber) ?? 0) > n && ((p.pointNumber ?? '').isNotEmpty || (p.connectedDeviceId ?? '').isNotEmpty)) || app.devices.any((d) => d.switchId == existing.id && (int.tryParse(d.switchPortNumber ?? '') ?? 0) > n))) { _message(context, 'لا يمكن تقليل عدد المنافذ قبل نقل أو حذف التوصيلات الواقعة خارج النطاق'); return; }
    final now = DateTime.now().toIso8601String();
    final item = NetworkSwitch(id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), switchNumber: number.text.trim(), name: name.text.trim(), floor: floor, location: location.text.trim(), portCount: n, connectionType: path, ports: existing?.ports ?? const [], notes: existing?.notes ?? '', createdAt: existing?.createdAt ?? now, updatedAt: now);
    final result = await app.saveNetworkSwitch(item);
    if (context.mounted) _message(context, result ?? 'تم حفظ السويتش');
  }

  Future<void> _editPoint(BuildContext context, NetworkSwitch sw, String portNumber, NetworkSwitchPort? old) async {
    final app = context.read<AppProvider>();
    final point = TextEditingController(text: old?.pointNumber);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('بيانات منفذ $portNumber'),
      content: TextField(controller: point, decoration: const InputDecoration(labelText: 'رقم النقطة الشبكية (اختياري)', hintText: 'يمكن تركه فارغاً وإضافته لاحقاً')),
      actions: [TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))],
    ));
    if (ok != true) return;
    final value = point.text.trim();
    if (value.isNotEmpty && app.networkSwitches.any((item) => item.ports.any((p) => !(item.id == sw.id && p.portNumber == portNumber) && p.pointNumber?.trim().toLowerCase() == value.toLowerCase()))) { _message(context, 'رقم النقطة مرتبط مسبقاً بمنفذ آخر'); return; }
    final ports = sw.ports.where((p) => p.portNumber != portNumber).toList()..add(NetworkSwitchPort(portNumber: portNumber, pointNumber: value.isEmpty ? null : value, connectedDeviceId: old?.connectedDeviceId, notes: old?.notes));
    final updated = NetworkSwitch(id: sw.id, switchNumber: sw.switchNumber, name: sw.name, floor: sw.floor, location: sw.location, portCount: sw.portCount, connectionType: sw.connectionType, ports: ports, notes: sw.notes, createdAt: sw.createdAt, updatedAt: DateTime.now().toIso8601String());
    final result = await app.saveNetworkSwitch(updated);
    if (context.mounted) _message(context, result ?? (value.isEmpty ? 'تم إبقاء المنفذ دون رقم نقطة' : 'تم حفظ رقم النقطة ويمكن ربطه بالحاسب لاحقاً'));
  }

  void _message(BuildContext context, String value) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value))); }
}