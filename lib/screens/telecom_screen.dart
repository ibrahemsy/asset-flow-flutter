import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class TelecomScreen extends StatelessWidget {
  const TelecomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppTheme.primary,
            tabs: [
              Tab(text: 'دليل الهواتف'),
              Tab(text: 'الشبكات'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Phone Directory
                Scaffold(
                  backgroundColor: AppTheme.background,
                  body: app.phoneDirectory.isEmpty
                      ? const Center(child: Text('لا توجد أرقام'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                          itemCount: app.phoneDirectory.length,
                          itemBuilder: (_, i) {
                            final p = app.phoneDirectory[i];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE0E7FF),
                                  child: Icon(Icons.phone, color: AppTheme.primary),
                                ),
                                title: Text(p.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${p.department} • ${p.officeLocation}'),
                                trailing: Text(p.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                              ),
                            );
                          },
                        ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => _addPhone(context, app),
                    child: const Icon(Icons.add),
                  ),
                ),
                // Networks
                Scaffold(
                  backgroundColor: AppTheme.background,
                  body: app.telecomNetworks.isEmpty
                      ? const Center(child: Text('لا توجد شبكات مسجلة'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                          itemCount: app.telecomNetworks.length,
                          itemBuilder: (_, i) {
                            final n = app.telecomNetworks[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: n.status == 'active'
                                      ? AppTheme.success.withOpacity(0.15)
                                      : AppTheme.danger.withOpacity(0.15),
                                  child: Icon(Icons.lan, color: n.status == 'active' ? AppTheme.success : AppTheme.danger),
                                ),
                                title: Text(n.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${n.type}\n${n.location}${n.ipRange != null ? ' • ${n.ipRange}' : ''}'),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => _addNetwork(context, app),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addPhone(BuildContext context, AppProvider app) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final officeCtrl = TextEditingController();
    final pbxCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('إضافة رقم هاتف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الموظف')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'القسم')),
              const SizedBox(height: 10),
              TextField(controller: officeCtrl, decoration: const InputDecoration(labelText: 'موقع المكتب')),
              const SizedBox(height: 10),
              TextField(controller: pbxCtrl, decoration: const InputDecoration(labelText: 'منفذ المقسم (PBX)')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final e = PhoneDirectoryEntry(
                    id: const Uuid().v4(),
                    phoneNumber: phoneCtrl.text.trim(),
                    employeeName: nameCtrl.text.trim(),
                    department: deptCtrl.text.trim(),
                    officeLocation: officeCtrl.text.trim(),
                    pbxPortNumber: pbxCtrl.text.trim(),
                    status: 'active',
                  );
                  final msg = await app.savePhoneEntry(e);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'تم الحفظ')));
                  }
                },
                child: const Text('حفظ'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _addNetwork(BuildContext context, AppProvider app) {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'شبكة داخلية');
    final locCtrl = TextEditingController();
    final ipCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('إضافة شبكة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الشبكة')),
              const SizedBox(height: 10),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'النوع')),
              const SizedBox(height: 10),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'الموقع')),
              const SizedBox(height: 10),
              TextField(controller: ipCtrl, decoration: const InputDecoration(labelText: 'نطاق IP')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final n = TelecomNetworkInfo(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    type: typeCtrl.text.trim(),
                    location: locCtrl.text.trim(),
                    ipRange: ipCtrl.text.trim().isEmpty ? null : ipCtrl.text.trim(),
                    status: 'active',
                  );
                  final msg = await app.saveTelecomNetwork(n);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'تم الحفظ')));
                  }
                },
                child: const Text('حفظ'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
