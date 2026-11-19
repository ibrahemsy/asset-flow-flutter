import 'package:flutter_test/flutter_test.dart';
import 'package:asset_flow_flutter/models/models.dart';
import 'package:asset_flow_flutter/utils/device_lookup.dart';

Device _device({
  String barcode = '',
  String serial = '',
  String asset = '',
}) {
  return Device(
    id: 'device-1',
    name: 'جهاز اختبار',
    category: DeviceCategory.laptop,
    manufacturer: 'Test',
    model: 'Model',
    serialNumber: serial,
    barcode: barcode,
    assetNumber: asset,
    purchaseDate: '2026-01-01',
    supplier: '',
    condition: DeviceCondition.good,
    status: DeviceStatus.inWarehouse,
    location: '',
    attachments: const [],
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
  );
}

void main() {
  group('Scanned device lookup', () {
    test('matches barcode ignoring surrounding whitespace and case', () {
      final device = _device(barcode: 'AbC-123');
      expect(findDeviceByScannedCode([device], '  abc-123  '), same(device));
    });

    test('matches serial number and asset number', () {
      final bySerial = _device(serial: 'SN-55');
      final byAsset = _device(asset: 'AST-77');

      expect(findDeviceByScannedCode([bySerial], 'sn-55'), same(bySerial));
      expect(findDeviceByScannedCode([byAsset], 'AST-77'), same(byAsset));
    });

    test('returns null for blank or unknown codes', () {
      final device = _device(barcode: 'KNOWN');
      expect(findDeviceByScannedCode([device], '   '), isNull);
      expect(findDeviceByScannedCode([device], 'UNKNOWN'), isNull);
      expect(findDeviceByScannedCode(const [], 'KNOWN'), isNull);
    });

    test('returns the first matching device when duplicate legacy values exist', () {
      final first = _device(barcode: 'DUP');
      final second = _device(barcode: 'DUP');
      expect(findDeviceByScannedCode([first, second], 'DUP'), same(first));
    });
  });
}
