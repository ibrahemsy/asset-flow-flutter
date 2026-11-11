import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_icons.dart';
import '../models/models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    final totalDevices = app.devices.length;
    final inWarehouse = app.devices.where((d) => d.status == DeviceStatus.inWarehouse).length;
    final assigned = app.devices
        .where((d) =>
            d.status == DeviceStatus.assignedEmployee ||
            d.status == DeviceStatus.assignedDepartment)
        .length;
    final inMaintenance = app.devices.where((d) => d.status == DeviceStatus.inMaintenance).length;
    final openTickets = app.tickets
        .where((t) => t.status != TicketStatus.closed && t.status != TicketStatus.repaired)
        .length;
    final pendingApprovals = app.pendingRequests.where((r) => r.status == 'pending').length;
    final activeCards = app.custodyCards.where((c) => c.status == 'active').length;

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'مرحباً، ${app.currentUser?.displayName?.split(' ').first ?? ''}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (app.isHeadOfDept)
                  const IconChip(icon: Icons.verified_rounded, label: 'رئيس', color: AppTheme.success)
                else
                  const IconChip(icon: Icons.engineering_rounded, label: 'فني', color: AppTheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            // زر إضافة جهاز جديد
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => app.openAddDevice(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة جهاز جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [
                _MiniStat(icon: AppIcons.devices, value: '$totalDevices', label: 'أجهزة', color: AppTheme.primary, onTap: () => app.setActiveTab('devices')),
                _MiniStat(icon: Icons.warehouse_rounded, value: '$inWarehouse', label: 'مستودع', color: AppTheme.success, onTap: () => app.setActiveTab('devices')),
                _MiniStat(icon: Icons.person_rounded, value: '$assigned', label: 'مسلّمة', color: AppTheme.accent, onTap: () => app.setActiveTab('devices')),
                _MiniStat(icon: AppIcons.maintenance, value: '$inMaintenance', label: 'صيانة', color: AppTheme.warning, onTap: () => app.setActiveTab('maintenance')),
                _MiniStat(icon: Icons.report_problem_rounded, value: '$openTickets', label: 'بلاغات', color: AppTheme.danger, onTap: () => app.setActiveTab('maintenance')),
                _MiniStat(icon: AppIcons.custody, value: '$activeCards', label: 'عهدة', color: const Color(0xFF7C3AED), onTap: () => app.setActiveTab('custody_card')),
              ],
            ),
            if (app.isHeadOfDept && pendingApprovals > 0) ...[
              const SizedBox(height: 14),
              Material(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => app.setActiveTab('approvals'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        const SectionIcon(icon: AppIcons.approvals, color: AppTheme.warning, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('$pendingApprovals طلب بانتظارك', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const Icon(Icons.chevron_left_rounded, color: AppTheme.warning),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Text('وصول سريع', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _QuickBtn(icon: AppIcons.devices, color: AppTheme.primary, label: 'جهاز', onTap: () => app.setActiveTab('devices')),
                _QuickBtn(icon: AppIcons.custody, color: const Color(0xFF7C3AED), label: 'عهدة', onTap: () => app.setActiveTab('custody_card')),
                _QuickBtn(icon: AppIcons.movements, color: AppTheme.accent, label: 'حركة', onTap: () => app.setActiveTab('movements')),
                _QuickBtn(icon: AppIcons.maintenance, color: AppTheme.warning, label: 'صيانة', onTap: () => app.setActiveTab('maintenance')),
                _QuickBtn(icon: AppIcons.reports, color: AppTheme.success, label: 'تقرير', onTap: () => app.setActiveTab('reports')),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(icon: AppIcons.movements, title: 'آخر الحركات', color: AppTheme.accent, onMore: () => app.setActiveTab('movements')),
            const SizedBox(height: 6),
            if (app.movements.isEmpty)
              const _EmptyHint(icon: AppIcons.movements, text: 'لا حركات بعد')
            else
              ...app.movements.take(4).map((m) => _CompactTile(
                    icon: AppIcons.movementType(m.type),
                    color: AppTheme.accent,
                    title: m.deviceName,
                    subtitle: m.type.labelAr,
                    trailing: m.date,
                  )),
            const SizedBox(height: 16),
            _SectionHeader(icon: AppIcons.maintenance, title: 'آخر البلاغات', color: AppTheme.warning, onMore: () => app.setActiveTab('maintenance')),
            const SizedBox(height: 6),
            if (app.tickets.isEmpty)
              const _EmptyHint(icon: AppIcons.maintenance, text: 'لا بلاغات')
            else
              ...app.tickets.take(4).map((t) => _CompactTile(
                    icon: AppIcons.priority(t.priority),
                    color: AppIcons.priorityColor(t.priority),
                    title: t.deviceName,
                    subtitle: t.status.labelAr,
                    trailing: t.priority.labelAr,
                  )),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _MiniStat({required this.icon, required this.value, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onMore;
  const _SectionHeader({required this.icon, required this.title, required this.color, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (onMore != null)
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            onPressed: onMore,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}

class _CompactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;
  const _CompactTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: SectionIcon(icon: icon, color: color, size: 36),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Text(trailing, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
