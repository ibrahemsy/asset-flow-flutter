import '../models/models.dart';

class SheetsExportResult {
  final String spreadsheetId;
  final String spreadsheetUrl;
  SheetsExportResult({required this.spreadsheetId, required this.spreadsheetUrl});
}

/// Google Sheets export needs a separate Google OAuth integration.
/// It is intentionally disabled rather than silently reusing Firebase credentials.
class SheetsService {
  Future<SheetsExportResult> exportInventoryToGoogleSheets({
    required String title,
    required List<Device> devices,
    required List<CustodyCard> custodyCards,
  }) async {
    throw UnsupportedError(
      'تصدير Google Sheets يحتاج إعداد Google OAuth مستقل. '
      'يمكن حالياً تصدير الملفات بصيغة Excel.',
    );
  }

  Future<SheetsExportResult> exportFullReportToSheets({
    required List<Device> devices,
    required List<CustodyCard> cards,
    required List<Movement> movements,
    required List<MaintenanceTicket> tickets,
  }) async {
    throw UnsupportedError(
      'تصدير Google Sheets يحتاج إعداد Google OAuth مستقل. '
      'يمكن حالياً تصدير الملفات بصيغة Excel.',
    );
  }
}
