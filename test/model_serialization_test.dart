import 'package:flutter_test/flutter_test.dart';
import 'package:asset_flow_flutter/models/models.dart';

void main() {
  group('Application model serialization', () {
    test('UserProfile preserves identity and role', () {
      final profile = UserProfile(
        id: 'user-1',
        email: 'staff@example.com',
        displayName: 'موظف تجريبي',
        role: UserRoleType.technician,
        department: 'الاتصالات',
        createdAt: '2026-11-15T00:00:00Z',
      );

      final restored = UserProfile.fromMap(profile.toMap(), profile.id);

      expect(restored.id, profile.id);
      expect(restored.email, profile.email);
      expect(restored.displayName, profile.displayName);
      expect(restored.role, UserRoleType.technician);
    });

    test('Device preserves barcode and inventory identifiers across Supabase mapping', () {
      final device = Device(
        id: 'device-asset-1',
        name: 'حاسوب محمول',
        category: DeviceCategory.laptop,
        manufacturer: 'Lenovo',
        model: 'ThinkPad',
        serialNumber: 'SN-2026-001',
        barcode: '8901234567890',
        assetNumber: 'AST-001',
        purchaseDate: '2026-01-10',
        supplier: 'المورد',
        condition: DeviceCondition.good,
        status: DeviceStatus.assignedEmployee,
        location: 'دمشق',
        attachments: const [],
        createdAt: '2026-11-15T00:00:00Z',
        updatedAt: '2026-11-15T00:00:00Z',
      );

      final restored = Device.fromMap(device.toMap(), device.id);

      expect(restored.id, device.id);
      expect(restored.barcode, '8901234567890');
      expect(restored.serialNumber, 'SN-2026-001');
      expect(restored.assetNumber, 'AST-001');
      expect(restored.category, DeviceCategory.laptop);
      expect(restored.status, DeviceStatus.assignedEmployee);
    });

    test('Unknown device enum values fall back safely', () {
      final restored = Device.fromMap({
        'name': 'جهاز غير معروف',
        'category': 'future_category',
        'condition': 'future_condition',
        'status': 'future_status',
      }, 'device-unknown');

      expect(restored.category, DeviceCategory.other);
      expect(restored.condition, DeviceCondition.good);
      expect(restored.status, DeviceStatus.inWarehouse);
    });

    test('PendingRequest preserves JSON payload and target table', () {
      final request = PendingRequest(
        id: 'req-1',
        actionType: 'add_device',
        title: 'إضافة جهاز',
        details: 'حاسوب تجريبي',
        requesterUid: 'auth-user-1',
        requesterEmail: 'staff@example.com',
        requesterName: 'موظف تجريبي',
        payload: const {'id': 'device-1', 'name': 'حاسوب'},
        targetCollection: 'devices',
        targetDocId: 'device-1',
        status: 'pending',
        createdAt: '2026-11-15T00:00:00Z',
      );

      final restored = PendingRequest.fromMap(request.toMap(), request.id);

      expect(restored.id, request.id);
      expect(restored.targetCollection, 'devices');
      expect(restored.payload['name'], 'حاسوب');
      expect(restored.status, 'pending');
    });

    test('Device preserves nested port mappings and attachments', () {
      final device = Device(
        id: 'device-network-1',
        name: 'سويتش تجريبي',
        category: DeviceCategory.switchDevice,
        manufacturer: 'Cisco',
        model: 'Catalyst',
        serialNumber: 'SW-001',
        barcode: 'SW-BAR-001',
        assetNumber: 'AST-SW-001',
        portsCount: 24,
        portMappings: [
          NetworkPortMapping(
            portNumber: '1',
            pointNumber: 'P-01',
            officeLocation: 'المكتب 1',
            connectedDevice: 'PC-01',
            notes: 'منفذ مستخدم',
          ),
        ],
        purchaseDate: '2026-01-01',
        supplier: 'المورد',
        condition: DeviceCondition.good,
        status: DeviceStatus.inWarehouse,
        location: 'غرفة الشبكة',
        attachments: [
          DeviceAttachment(
            id: 'att-1',
            name: 'صورة الجهاز',
            type: 'image',
            dataUrl: 'data:image/png;base64,AA==',
            uploadedAt: '2026-11-15T00:00:00Z',
          ),
        ],
        createdAt: '2026-11-15T00:00:00Z',
        updatedAt: '2026-11-15T00:00:00Z',
      );

      final restored = Device.fromMap(device.toMap(), device.id);

      expect(restored.portsCount, 24);
      expect(restored.portMappings, hasLength(1));
      expect(restored.portMappings!.single.portNumber, '1');
      expect(restored.portMappings!.single.connectedDevice, 'PC-01');
      expect(restored.attachments, hasLength(1));
      expect(restored.attachments.single.name, 'صورة الجهاز');
      expect(restored.attachments.single.dataUrl, 'data:image/png;base64,AA==');
    });

    test('Custody item preserves barcode, item code, linked device and images', () {
      final item = CustodyCardItem(
        id: 'item-1',
        no: 1,
        name: 'حاسوب محمول',
        description: 'حاسوب الموظف',
        unit: 'قطعة',
        quantity: 1,
        serialNumber: 'LAP-001',
        barcode: '8901234567890',
        itemCode: 'MAT-001',
        receiptDetails: 'تسليم',
        receiptDate: '2026-11-15',
        returnDetails: '',
        custodyNumber: 'C-001',
        returnDate: '',
        balance: 1,
        notes: '',
        deviceId: 'device-1',
        imageUrls: const ['https://example.test/item.png'],
      );

      final restored = CustodyCardItem.fromMap(item.toMap());

      expect(restored.barcode, item.barcode);
      expect(restored.itemCode, item.itemCode);
      expect(restored.deviceId, item.deviceId);
      expect(restored.imageUrls, item.imageUrls);
    });

    test('Movement preserves scanned barcode through Supabase mapping', () {
      final movement = Movement(
        id: 'movement-1',
        referenceNumber: 'MOV-001',
        type: MovementType.handover,
        deviceId: 'device-1',
        deviceName: 'حاسوب محمول',
        serialNumber: 'LAP-001',
        barcode: '8901234567890',
        fromEntity: 'المستودع',
        toEntity: 'الموظف',
        executorName: 'مسؤول العهدة',
        date: '2026-11-15',
        reason: 'تسليم',
        createdAt: '2026-11-15T00:00:00Z',
      );

      final restored = Movement.fromMap(movement.toMap(), movement.id);

      expect(restored.barcode, movement.barcode);
      expect(restored.deviceId, movement.deviceId);
      expect(restored.referenceNumber, movement.referenceNumber);
    });
  });
}
