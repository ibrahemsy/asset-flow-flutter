import 'package:flutter/material.dart';
import '../models/models.dart';
import 'app_theme.dart';

/// أيقونات وألوان مختصرة للأقسام والحالات — بدل النصوص الطويلة
class AppIcons {
  // -------------------- التنقل --------------------
  static const dashboard = Icons.space_dashboard_rounded;
  static const custody = Icons.badge_rounded;
  static const devices = Icons.devices_other_rounded;
  static const movements = Icons.swap_horiz_rounded;
  static const telecom = Icons.phone_in_talk_rounded;
  static const network = Icons.hub_rounded;
  static const maintenance = Icons.handyman_rounded;
  static const reports = Icons.analytics_rounded;
  static const approvals = Icons.fact_check_rounded;
  static const audit = Icons.history_rounded;
  static const users = Icons.manage_accounts_rounded;

  // -------------------- تصنيف الأجهزة --------------------
  static IconData category(DeviceCategory c) {
    switch (c) {
      case DeviceCategory.desktop:
        return Icons.desktop_windows_rounded;
      case DeviceCategory.laptop:
        return Icons.laptop_mac_rounded;
      case DeviceCategory.monitor:
        return Icons.monitor_rounded;
      case DeviceCategory.printer:
        return Icons.print_rounded;
      case DeviceCategory.scanner:
        return Icons.document_scanner_rounded;
      case DeviceCategory.ups:
        return Icons.battery_charging_full_rounded;
      case DeviceCategory.router:
        return Icons.router_rounded;
      case DeviceCategory.switchDevice:
        return Icons.device_hub_rounded;
      case DeviceCategory.accessPoint:
        return Icons.wifi_rounded;
      case DeviceCategory.wirelessRadio:
        return Icons.settings_input_antenna_rounded;
      case DeviceCategory.telephony:
        return Icons.phone_rounded;
      case DeviceCategory.modem:
        return Icons.cell_tower_rounded;
      case DeviceCategory.cablesFiber:
        return Icons.cable_rounded;
      case DeviceCategory.telecomGear:
        return Icons.settings_input_component_rounded;
      case DeviceCategory.peripherals:
        return Icons.mouse_rounded;
      case DeviceCategory.spareParts:
        return Icons.memory_rounded;
      case DeviceCategory.other:
        return Icons.category_rounded;
    }
  }

  static Color categoryColor(DeviceCategory c) {
    switch (c) {
      case DeviceCategory.desktop:
      case DeviceCategory.laptop:
        return const Color(0xFF3B82F6);
      case DeviceCategory.monitor:
        return const Color(0xFF6366F1);
      case DeviceCategory.printer:
      case DeviceCategory.scanner:
        return const Color(0xFF8B5CF6);
      case DeviceCategory.ups:
        return const Color(0xFF10B981);
      case DeviceCategory.router:
      case DeviceCategory.switchDevice:
      case DeviceCategory.accessPoint:
        return const Color(0xFF0EA5E9);
      case DeviceCategory.wirelessRadio:
      case DeviceCategory.telephony:
      case DeviceCategory.modem:
        return const Color(0xFFF59E0B);
      case DeviceCategory.cablesFiber:
      case DeviceCategory.telecomGear:
        return const Color(0xFF14B8A6);
      default:
        return AppTheme.textSecondary;
    }
  }

  // -------------------- حالة الجهاز --------------------
  static IconData deviceStatus(DeviceStatus s) {
    switch (s) {
      case DeviceStatus.inWarehouse:
        return Icons.warehouse_rounded;
      case DeviceStatus.assignedEmployee:
        return Icons.person_rounded;
      case DeviceStatus.assignedDepartment:
        return Icons.apartment_rounded;
      case DeviceStatus.inMaintenance:
        return Icons.build_circle_rounded;
      case DeviceStatus.decommissioned:
        return Icons.block_rounded;
    }
  }

  static Color statusColor(DeviceStatus s) {
    switch (s) {
      case DeviceStatus.inWarehouse:
        return AppTheme.success;
      case DeviceStatus.assignedEmployee:
      case DeviceStatus.assignedDepartment:
        return AppTheme.primary;
      case DeviceStatus.inMaintenance:
        return AppTheme.warning;
      case DeviceStatus.decommissioned:
        return AppTheme.danger;
    }
  }

  // -------------------- الحالة الفنية --------------------
  static IconData condition(DeviceCondition c) {
    switch (c) {
      case DeviceCondition.excellent:
        return Icons.verified_rounded;
      case DeviceCondition.good:
        return Icons.thumb_up_alt_rounded;
      case DeviceCondition.needsMaintenance:
        return Icons.warning_amber_rounded;
      case DeviceCondition.defective:
        return Icons.error_rounded;
      case DeviceCondition.outOfService:
        return Icons.do_not_disturb_on_rounded;
    }
  }

  static Color conditionColor(DeviceCondition c) {
    switch (c) {
      case DeviceCondition.excellent:
        return AppTheme.success;
      case DeviceCondition.good:
        return const Color(0xFF22C55E);
      case DeviceCondition.needsMaintenance:
        return AppTheme.warning;
      case DeviceCondition.defective:
        return AppTheme.danger;
      case DeviceCondition.outOfService:
        return AppTheme.textSecondary;
    }
  }

  // -------------------- أولوية الصيانة --------------------
  static IconData priority(TicketPriority p) {
    switch (p) {
      case TicketPriority.critical:
        return Icons.priority_high_rounded;
      case TicketPriority.high:
        return Icons.arrow_upward_rounded;
      case TicketPriority.normal:
        return Icons.remove_rounded;
      case TicketPriority.low:
        return Icons.arrow_downward_rounded;
    }
  }

  static Color priorityColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.critical:
        return AppTheme.danger;
      case TicketPriority.high:
        return AppTheme.warning;
      case TicketPriority.normal:
        return AppTheme.primary;
      case TicketPriority.low:
        return AppTheme.textSecondary;
    }
  }

  // -------------------- حالة البلاغ --------------------
  static IconData ticketStatus(TicketStatus s) {
    switch (s) {
      case TicketStatus.newTicket:
        return Icons.fiber_new_rounded;
      case TicketStatus.inProgress:
        return Icons.hourglass_top_rounded;
      case TicketStatus.waitingSpareParts:
        return Icons.inventory_2_rounded;
      case TicketStatus.repaired:
        return Icons.check_circle_rounded;
      case TicketStatus.closed:
        return Icons.lock_rounded;
    }
  }

  // -------------------- نوع الحركة --------------------
  static IconData movementType(MovementType t) {
    switch (t) {
      case MovementType.handover:
        return Icons.handshake_rounded;
      case MovementType.returnDevice:
        return Icons.keyboard_return_rounded;
      case MovementType.transferEmployee:
        return Icons.people_alt_rounded;
      case MovementType.transferDept:
        return Icons.compare_arrows_rounded;
      case MovementType.replacement:
        return Icons.find_replace_rounded;
      case MovementType.decommission:
        return Icons.delete_forever_rounded;
      case MovementType.newIntake:
        return Icons.add_box_rounded;
    }
  }
}

/// شريحة أيقونة مختصرة (بدل نص طويل)
class IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  const IconChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

/// أيقونة دائرية ملونة للأقسام
class SectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const SectionIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
