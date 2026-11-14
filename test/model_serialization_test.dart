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
  });
}
