import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final logs = app.auditLogs;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: logs.isEmpty
          ? const Center(child: Text('لا يوجد سجل تدقيق بعد', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final log = logs[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.history, color: AppTheme.primary, size: 20),
                    ),
                    title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('${log.details}\n${log.userName} • ${log.timestamp.split('T').first} ${log.timestamp.contains('T') ? log.timestamp.split('T').last.substring(0, 5) : ''}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
