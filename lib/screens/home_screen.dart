import 'package:flutter/material.dart';
import 'admin_handover_screen.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_icons.dart';
import 'dashboard_screen.dart';
import 'devices_screen.dart';
import 'custody_screen.dart';
import 'movements_screen.dart';
import 'maintenance_screen.dart';
import 'telecom_screen.dart';
import 'reports_screen.dart';
import 'approvals_screen.dart';
import 'audit_screen.dart';
import 'users_screen.dart';
import 'network_map_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomIndex = 0;

  final List<_NavItem> _bottomItems = const [
    _NavItem(icon: AppIcons.dashboard, label: 'الرئيسية', tab: 'dashboard'),
    _NavItem(icon: AppIcons.custody, label: 'العهدة', tab: 'custody_card'),
    _NavItem(icon: AppIcons.devices, label: 'الأجهزة', tab: 'devices'),
    _NavItem(icon: AppIcons.network, label: 'الشبكة', tab: 'network_map'),
    _NavItem(icon: AppIcons.maintenance, label: 'الصيانة', tab: 'maintenance'),
  ];

  Widget _buildBody(String tab) {
    switch (tab) {
      case 'dashboard':
        return const DashboardScreen();
      case 'custody_card':
        return const CustodyScreen();
      case 'devices':
        return const DevicesScreen();
      case 'movements':
        return const MovementsScreen();
      case 'telecom':
        return const TelecomScreen();
      case 'network_map':
        return const NetworkMapScreen();
      case 'maintenance':
        return const MaintenanceScreen();
      case 'reports':
        return const ReportsScreen();
      case 'approvals':
        return const ApprovalsScreen();
      case 'users':
        return const UsersScreen();
      case 'audit':
        return const AuditScreen();
      case 'admin_handover':
        return const AdminHandoverScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final pendingCount = app.pendingRequests.where((r) => r.status == 'pending').length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_rounded, size: 22),
              const SizedBox(width: 8),
              const Text('إدارة الأصول', style: TextStyle(fontSize: 17)),
            ],
          ),
          actions: [
            if (app.isSyncing)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            // دليل الاستخدام
            IconButton(
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: 'دليل الاستخدام',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                );
              },
            ),
            // تقارير
            IconButton(
              icon: const Icon(AppIcons.reports),
              tooltip: 'التقارير',
              onPressed: () => app.setActiveTab('reports'),
            ),
            // طلبات الاعتماد
            if (app.isHeadOfDept)
              IconButton(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: const Icon(AppIcons.approvals),
                ),
                tooltip: 'الاعتماد',
                onPressed: () => app.setActiveTab('approvals'),
              ),
            // القائمة
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                switch (value) {
                  case 'logout':
                    await app.logout();
                    break;
                  case 'audit':
                    app.setActiveTab('audit');
                    break;
                  case 'users':
                    app.setActiveTab('users');
                    break;
                  case 'telecom':
                    app.setActiveTab('telecom');
                    break;
                  case 'movements':
                    app.setActiveTab('movements');
                    break;
                  case 'help':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(
                          (app.currentUser?.displayName ?? '?')[0],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.currentUser?.displayName ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(
                                  app.isHeadOfDept ? Icons.verified_rounded : Icons.engineering_rounded,
                                  size: 12,
                                  color: app.isHeadOfDept ? AppTheme.success : AppTheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  app.isHeadOfDept ? 'رئيس' : 'فني',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: app.isHeadOfDept ? AppTheme.success : AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'movements',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(AppIcons.movements, size: 20),
                    title: Text('الحركات', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'telecom',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(AppIcons.telecom, size: 20),
                    title: Text('الهواتف', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'audit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(AppIcons.audit, size: 20),
                    title: Text('السجل', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'help',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.menu_book_rounded, size: 20),
                    title: Text('دليل الاستخدام', style: TextStyle(fontSize: 13)),
                  ),
                ),
                if (app.isHeadOfDept)
                  const PopupMenuItem(
                    value: 'users',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(AppIcons.users, size: 20),
                      title: Text('الإدارة', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout_rounded, size: 20, color: AppTheme.danger),
                    title: Text('خروج', style: TextStyle(fontSize: 13, color: AppTheme.danger)),
                  ),
                ),
              ],
            ),
          ],
        ),
        drawer: _buildDrawer(app, pendingCount),
        body: app.isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 12),
                    Text('جارٍ التحميل...', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              )
            : _buildBody(app.activeTab),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _bottomIndex,
          onDestinationSelected: (i) {
            setState(() => _bottomIndex = i);
            app.setActiveTab(_bottomItems[i].tab);
          },
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _bottomItems
              .map((item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon, color: AppTheme.primary),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDrawer(AppProvider app, int pendingCount) {
    final items = [
      _DrawerItem(AppIcons.dashboard, 'الرئيسية', 'dashboard', AppTheme.primary),
      _DrawerItem(AppIcons.custody, 'العهدة', 'custody_card', const Color(0xFF7C3AED)),
      _DrawerItem(AppIcons.devices, 'الأجهزة', 'devices', const Color(0xFF3B82F6)),
      _DrawerItem(AppIcons.movements, 'الحركات', 'movements', AppTheme.accent),
      _DrawerItem(AppIcons.telecom, 'الهواتف', 'telecom', const Color(0xFFF59E0B)),
      _DrawerItem(AppIcons.network, 'الشبكة', 'network_map', const Color(0xFF0EA5E9)),
      _DrawerItem(AppIcons.maintenance, 'الصيانة', 'maintenance', AppTheme.warning),
      _DrawerItem(AppIcons.reports, 'التقارير', 'reports', const Color(0xFF10B981)),
      if (app.isHeadOfDept)
        _DrawerItem(AppIcons.approvals, 'الاعتماد', 'approvals', AppTheme.danger, badge: pendingCount),
      _DrawerItem(AppIcons.audit, 'السجل', 'audit', AppTheme.textSecondary),
      _DrawerItem(Icons.swap_horiz_rounded, 'تسليم / استلام الإدارة', 'admin_handover', AppTheme.primaryDark),
      if (app.isHeadOfDept) _DrawerItem(AppIcons.users, 'الإدارة', 'users', AppTheme.primaryDark),
    ];

    return Drawer(
      child: Column(
        children: [
          // رأس مضغوط
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    (app.currentUser?.displayName ?? '?')[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.currentUser?.displayName ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            app.isHeadOfDept ? Icons.verified_rounded : Icons.engineering_rounded,
                            size: 13,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            app.isHeadOfDept ? 'رئيس الدائرة' : 'فني',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: items.map((item) {
                final selected = app.activeTab == item.tab;
                return ListTile(
                  dense: true,
                  leading: SectionIcon(icon: item.icon, color: item.color, size: 36),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                      color: selected ? item.color : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: item.badge != null && item.badge! > 0
                      ? Badge(label: Text('${item.badge}'))
                      : (selected ? Icon(Icons.circle, size: 8, color: item.color) : null),
                  selected: selected,
                  selectedTileColor: item.color.withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    app.setActiveTab(item.tab);
                    Navigator.pop(context);
                    final idx = _bottomItems.indexWhere((b) => b.tab == item.tab);
                    if (idx >= 0) setState(() => _bottomIndex = idx);
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const SectionIcon(icon: Icons.logout_rounded, color: AppTheme.danger, size: 36),
            title: const Text('خروج', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              await app.logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String tab;
  const _NavItem({required this.icon, required this.label, required this.tab});
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final String tab;
  final Color color;
  final int? badge;
  const _DrawerItem(this.icon, this.label, this.tab, this.color, {this.badge});
}
