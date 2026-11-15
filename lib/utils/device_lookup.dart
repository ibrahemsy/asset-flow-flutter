import '../models/models.dart';

/// Finds an inventory device by barcode, serial number, or asset number.
/// Comparison ignores surrounding whitespace and letter casing.
Device? findDeviceByScannedCode(Iterable<Device> devices, String rawCode) {
  final code = rawCode.trim().toLowerCase();
  if (code.isEmpty) return null;

  for (final device in devices) {
    if (device.barcode.trim().toLowerCase() == code ||
        device.serialNumber.trim().toLowerCase() == code ||
        device.assetNumber.trim().toLowerCase() == code) {
      return device;
    }
  }
  return null;
}
