import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

/// مخطط تلقائي مشتق من بيانات الحواسيب والسويتشات.
class NetworkMapScreen extends StatelessWidget {
  const NetworkMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final computers = app.devices.where((d) =>
      (d.category == DeviceCategory.desktop || d.category == DeviceCategory.laptop) &&
      (d.networkConnection == 'internalServer' || d.networkConnection == 'externalInternet')).toList();
    final internal = computers.where((d) => d.networkConnection == 'internalServer').toList();
    final external = computers.where((d) => d.networkConnection == 'externalInternet').toList();
    final unset = app.devices.where((d) =>
      (d.category == DeviceCategory.desktop || d.category == DeviceCategory.laptop) &&
      (d.networkConnection == null || d.networkConnection!.isEmpty)).length;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        const Text('مخطط الشبكة التلقائي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('يُنشأ المخطط من مسار اتصال كل حاسب ورقم السويتش والطابق المسجلين في بطاقة الجهاز.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _stat('الحواسيب المسجلة', computers.length, Colors.cyanAccent),
          _stat('سيرفر داخلي', internal.length, Colors.lightGreenAccent),
          _stat('إنترنت خارجي', external.length, Colors.orangeAccent),
          _stat('غير محدد', unset, Colors.amberAccent),
        ]),
        const SizedBox(height: 18),
        _section('مسار السيرفر الداخلي', internal, Icons.dns_rounded, Colors.lightGreenAccent),
        const SizedBox(height: 14),
        _section('مسار الإنترنت الخارجي', external, Icons.public_rounded, Colors.orangeAccent),
        if (unset > 0) ...[
          const SizedBox(height: 14),
          Text('$unset حاسباً لم تُحدد له جهة الاتصال. افتح بطاقة الجهاز لإدخال بيانات الشبكة.', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        const Text('تنبيه: المخطط يعرض التوصيلات المسجلة ولا يؤكد الاتصال الحي. التحقق الفعلي يحتاج تكاملاً مستقلاً مع SNMP أو نظام مراقبة الشبكة.', style: TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }

  Widget _stat(String label, int value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(.35))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value.toString(), style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]),
  );

  Widget _section(String title, List<Device> devices, IconData icon, Color color) {
    final floors = <String, List<Device>>{};
    for (final d in devices) {
      final floor = (d.switchFloor ?? '').trim().isEmpty ? 'طابق غير محدد' : d.switchFloor!;
      floors.putIfAbsent(floor, () => []).add(d);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15))]),
        const SizedBox(height: 12),
        if (devices.isEmpty) const Text('لا توجد حواسيب مسجلة ضمن هذا المسار.', style: TextStyle(color: Colors.white38, fontSize: 12))
        else ...floors.entries.map((entry) {
          final switches = <String, List<Device>>{};
          for (final d in entry.value) {
            final sw = (d.switchNumber ?? '').trim().isEmpty ? 'سويتش غير محدد' : 'السويتش ${d.switchNumber}';
            switches.putIfAbsent(sw, () => []).add(d);
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.apartment_rounded, color: Colors.white70, size: 17), const SizedBox(width: 6), Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 8),
              ...switches.entries.map((sw) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.device_hub_rounded, color: color, size: 17), const SizedBox(width: 6), Text(sw.key, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)), const Spacer(), Text('${sw.value.length} حاسب', style: const TextStyle(color: Colors.white38, fontSize: 10))]),
                const SizedBox(height: 6),
                Wrap(spacing: 7, runSpacing: 7, children: sw.value.map((d) => Container(
                  width: 145, padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(.3))),
                  child: Row(children: [
                    Icon(d.category == DeviceCategory.laptop ? Icons.laptop_mac_rounded : Icons.desktop_windows_rounded, color: color, size: 20),
                    const SizedBox(width: 7),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('منفذ: ${(d.switchPortNumber ?? '').isEmpty ? '—' : d.switchPortNumber!}', style: const TextStyle(color: Colors.white54, fontSize: 9)),
                      if ((d.ipAddress ?? '').isNotEmpty) Text(d.ipAddress!, style: const TextStyle(color: Colors.white38, fontSize: 9)),
                    ])),
                  ]),
                )).toList()),
                const SizedBox(height: 8),
              ])),
            ]),
          );
        }),
      ]),
    );
  }
}