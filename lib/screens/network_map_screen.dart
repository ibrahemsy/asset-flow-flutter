import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';

/// رسم هيكل الشبكة: إنترنت → ألياف → سيرفرات → سويتشات → مكاتب + شبكة المقاسم
class NetworkMapScreen extends StatelessWidget {
  const NetworkMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    final servers = app.devices.where((d) =>
        d.name.contains('سيرفر') || d.name.toLowerCase().contains('server')).toList();
    final switches = app.devices.where((d) => d.category == DeviceCategory.switchDevice).toList();
    final routers = app.devices.where((d) => d.category == DeviceCategory.router).toList();
    final aps = app.devices.where((d) => d.category == DeviceCategory.accessPoint).toList();
    final fiber = app.devices.where((d) => d.category == DeviceCategory.cablesFiber).toList();
    final phones = app.phoneDirectory;
    final networks = app.telecomNetworks;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: Colors.cyanAccent, size: 22),
              const SizedBox(width: 8),
              const Text('هيكل الشبكة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              _dot(Colors.orangeAccent, 'نت'),
              _dot(Colors.purpleAccent, 'ألياف'),
              _dot(Colors.cyanAccent, 'سيرفر'),
              _dot(Colors.lightGreenAccent, 'سويتش'),
            ],
          ),
          const SizedBox(height: 16),

          _layer('الإنترنت / البوابة', Icons.public_rounded, Colors.orangeAccent, Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _node(Icons.cloud_rounded, 'مزود الخدمة\nISP', Colors.orangeAccent),
                _node(Icons.router_rounded, 'راوتر رئيسي\nGateway', Colors.amber),
                ...routers.take(2).map((r) => _node(Icons.router_rounded, r.name, Colors.orange, sub: r.ipAddress)),
              ]),
            ),
            _arrow('اتصال إنترنت'),
          ])),

          _layer('الكابلات الضوئية (Fiber)', Icons.cable_rounded, Colors.purpleAccent, Column(children: [
            if (fiber.isEmpty)
              const Text('لا كابلات مسجّلة — أضفها من الأجهزة', style: TextStyle(color: Colors.white38, fontSize: 12))
            else
              Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: fiber.map((f) => _node(Icons.cable_rounded, f.name, Colors.purpleAccent, sub: f.location)).toList()),
            _arrow('نقل ضوئي'),
          ])),

          _layer('السيرفرات الداخلية', Icons.dns_rounded, Colors.cyanAccent, Column(children: [
            if (servers.isEmpty && networks.where((n) => n.type.contains('خادم')).isEmpty)
              const Text('لا سيرفرات مسجّلة', style: TextStyle(color: Colors.white38, fontSize: 12))
            else
              Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                ...servers.map((s) => _node(Icons.dns_rounded, s.name, Colors.cyanAccent, sub: s.ipAddress ?? s.location)),
                ...networks.where((n) => n.type.contains('خادم') || n.name.toLowerCase().contains('server')).map((n) => _node(Icons.storage_rounded, n.name, Colors.tealAccent, sub: n.ipRange ?? n.location)),
              ]),
            _arrow('LAN'),
          ])),

          _layer('السويتشات ونقاط البث', Icons.device_hub_rounded, Colors.lightGreenAccent, Column(children: [
            if (switches.isEmpty && aps.isEmpty)
              const Text('لا سويتشات / AP', style: TextStyle(color: Colors.white38, fontSize: 12))
            else
              Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                ...switches.map((s) => _node(Icons.device_hub_rounded, s.name, Colors.lightGreenAccent, sub: '${s.portsCount ?? "?"} منفذ')),
                ...aps.map((a) => _node(Icons.wifi_rounded, a.name, Colors.greenAccent, sub: a.location)),
              ]),
            _arrow('إلى المكاتب'),
          ])),

          _layer('شبكة المقاسم الأرضية (PBX)', Icons.phone_in_talk_rounded, Colors.amberAccent, Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _node(Icons.settings_phone_rounded, 'المقسم المركزي\nPBX', Colors.amberAccent, large: true)),
              const SizedBox(height: 12),
              if (phones.isEmpty)
                const Text('لا أرقام في دليل الهواتف', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)
              else
                ..._group(phones).entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.apartment_rounded, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(e.key, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(' (${e.value.length})', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: e.value.map((p) {
                      final active = p.status == 'active';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? Colors.amber.withOpacity(0.15) : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: active ? Colors.amberAccent.withOpacity(0.5) : Colors.white12),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.phone_rounded, size: 12, color: active ? Colors.amberAccent : Colors.white38),
                          const SizedBox(width: 4),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.phoneNumber, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(p.employeeName.length > 14 ? '${p.employeeName.substring(0, 14)}…' : p.employeeName, style: const TextStyle(color: Colors.white54, fontSize: 9)),
                          ]),
                          if (p.pbxPortNumber.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text('P${p.pbxPortNumber}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                          ],
                        ]),
                      );
                    }).toList()),
                  ]),
                )),
            ],
          )),

          if (networks.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('الشبكات المسجّلة', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...networks.map((n) => Card(
              color: const Color(0xFF1E293B),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.lan_rounded, color: n.status == 'active' ? Colors.lightGreenAccent : Colors.redAccent),
                title: Text(n.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text('${n.type} • ${n.location}${n.ipRange != null ? ' • ${n.ipRange}' : ''}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Map<String, List<PhoneDirectoryEntry>> _group(List<PhoneDirectoryEntry> phones) {
    final map = <String, List<PhoneDirectoryEntry>>{};
    for (final p in phones) {
      map.putIfAbsent(p.department.isEmpty ? 'عام' : p.department, () => []).add(p);
    }
    return map;
  }
}

Widget _layer(String title, IconData icon, Color color, Widget child) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
      const SizedBox(height: 12),
      child,
    ]),
  );
}

Widget _node(IconData icon, String label, Color color, {String? sub, bool large = false}) {
  final size = large ? 56.0 : 44.0;
  return Container(
    width: large ? 100 : 88,
    padding: const EdgeInsets.all(8),
    child: Column(children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
        ),
        child: Icon(icon, color: color, size: large ? 28 : 22),
      ),
      const SizedBox(height: 6),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
      if (sub != null && sub.isNotEmpty)
        Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
    ]),
  );
}

Widget _arrow(String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 40, height: 2, color: Colors.white24),
      const Icon(Icons.arrow_downward_rounded, color: Colors.white38, size: 16),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      const SizedBox(width: 6),
      const Icon(Icons.arrow_downward_rounded, color: Colors.white38, size: 16),
      Container(width: 40, height: 2, color: Colors.white24),
    ]),
  );
}

Widget _dot(Color color, String label) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
    ]),
  );
}
