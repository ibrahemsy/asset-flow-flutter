import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'firebase_service.dart';

class SheetsExportResult {
  final String spreadsheetId;
  final String spreadsheetUrl;

  SheetsExportResult({required this.spreadsheetId, required this.spreadsheetUrl});
}

class SheetsService {
  static final SheetsService _instance = SheetsService._internal();
  factory SheetsService() => _instance;
  SheetsService._internal();

  final FirebaseService _firebase = FirebaseService();

  /// تصدير الأجهزة وبطاقات العهدة إلى Google Sheets جديد
  Future<SheetsExportResult> exportInventoryToGoogleSheets({
    required String title,
    required List<Device> devices,
    required List<CustodyCard> custodyCards,
  }) async {
    final token = await _firebase.getGoogleAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception(
        'يرجى تسجيل الدخول بحساب Google أولاً لمنح الإذن بربط جداول Google Sheets.\n'
        'تأكد من الموافقة على صلاحية spreadsheets عند تسجيل الدخول.',
      );
    }

    // 1. إنشاء جدول جديد
    final createResponse = await http.post(
      Uri.parse('https://sheets.googleapis.com/v4/spreadsheets'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'properties': {
          'title': '$title - ${_arabicDate()}',
          'locale': 'ar_SY',
          'timeZone': 'Asia/Damascus',
        },
        'sheets': [
          {
            'properties': {'title': 'سجل الحواسيب والتجهيزات'},
          },
          {
            'properties': {'title': 'بطاقات العهدة الشخصية'},
          },
        ],
      }),
    );

    if (createResponse.statusCode < 200 || createResponse.statusCode >= 300) {
      final err = jsonDecode(createResponse.body);
      throw Exception(err['error']?['message'] ?? 'فشل إنشاء جدول Google Sheets (${createResponse.statusCode})');
    }

    final spreadsheetData = jsonDecode(createResponse.body) as Map<String, dynamic>;
    final spreadsheetId = spreadsheetData['spreadsheetId'] as String;
    final spreadsheetUrl = spreadsheetData['spreadsheetUrl'] as String? ??
        'https://docs.google.com/spreadsheets/d/$spreadsheetId';

    // 2. تجهيز صفوف الأجهزة
    final deviceRows = <List<dynamic>>[
      [
        'م',
        'اسم الجهاز',
        'النوع',
        'الشركة المصنعة',
        'الطراز',
        'الرقم التسلسلي',
        'رقم العهدة / المالي',
        'الحالة الفنية',
        'حالة التواجد',
        'الموقع / القسم',
        'الموظف المسؤول',
        'تاريخ الاستلام',
        'ملاحظات',
      ],
      ...devices.asMap().entries.map((e) {
        final d = e.value;
        return [
          e.key + 1,
          d.name,
          d.category.labelAr,
          d.manufacturer,
          d.model,
          d.serialNumber,
          d.assetNumber,
          d.condition.labelAr,
          d.status.labelAr,
          d.location,
          d.assignedEmployee ?? '-',
          d.deliveryDate ?? '-',
          d.notes ?? '',
        ];
      }),
    ];

    // 3. تجهيز صفوف بطاقات العهدة
    final cardRows = <List<dynamic>>[
      [
        'رقم البطاقة',
        'الاسم الثلاثي للموظف',
        'الرقم الوطني',
        'الصفة الوظيفية',
        'المديرية',
        'الدائرة / الشعبة',
        'مركز العمل',
        'تاريخ الإنشاء',
        'عدد المواد المسلمة',
        'الحالة',
        'مصادقة الإدارة',
      ],
      ...custodyCards.map((c) => [
            c.cardNumber,
            c.employeeName,
            c.nationalId,
            c.jobTitle,
            c.directorate,
            '${c.department} - ${c.division}',
            c.workCenter,
            c.creationDate,
            c.items.length,
            c.status == 'active' ? 'نشطة ومسجلة' : 'مؤرشفة',
            c.adminEndorsement.isNotEmpty ? c.adminEndorsement : 'تمت المصادقة',
          ]),
    ];

    // 4. كتابة البيانات
    final updateResponse = await http.post(
      Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values:batchUpdate',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'valueInputOption': 'USER_ENTERED',
        'data': [
          {
            'range': 'سجل الحواسيب والتجهيزات!A1',
            'values': deviceRows,
          },
          {
            'range': 'بطاقات العهدة الشخصية!A1',
            'values': cardRows,
          },
        ],
      }),
    );

    if (updateResponse.statusCode < 200 || updateResponse.statusCode >= 300) {
      final err = jsonDecode(updateResponse.body);
      throw Exception(err['error']?['message'] ?? 'فشل تحديث البيانات في Google Sheets');
    }

    return SheetsExportResult(
      spreadsheetId: spreadsheetId,
      spreadsheetUrl: spreadsheetUrl,
    );
  }

  /// تصدير تقرير كامل (أجهزة + عهدة + حركات + صيانة) إلى Sheets
  Future<SheetsExportResult> exportFullReportToSheets({
    required List<Device> devices,
    required List<CustodyCard> cards,
    required List<Movement> movements,
    required List<MaintenanceTicket> tickets,
  }) async {
    final token = await _firebase.getGoogleAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('يرجى تسجيل الدخول بحساب Google مع صلاحية Sheets');
    }

    final createResponse = await http.post(
      Uri.parse('https://sheets.googleapis.com/v4/spreadsheets'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'properties': {
          'title': 'تقرير شامل - دائرة الاتصالات - ${_arabicDate()}',
          'locale': 'ar_SY',
          'timeZone': 'Asia/Damascus',
        },
        'sheets': [
          {'properties': {'title': 'الأجهزة'}},
          {'properties': {'title': 'العهدة'}},
          {'properties': {'title': 'الحركات'}},
          {'properties': {'title': 'الصيانة'}},
        ],
      }),
    );

    if (createResponse.statusCode < 200 || createResponse.statusCode >= 300) {
      final err = jsonDecode(createResponse.body);
      throw Exception(err['error']?['message'] ?? 'فشل إنشاء الجدول');
    }

    final data = jsonDecode(createResponse.body) as Map<String, dynamic>;
    final id = data['spreadsheetId'] as String;
    final url = data['spreadsheetUrl'] as String? ?? 'https://docs.google.com/spreadsheets/d/$id';

    final deviceRows = [
      ['م', 'الاسم', 'التصنيف', 'الشركة', 'الطراز', 'السيريال', 'الحالة', 'التواجد', 'الموقع', 'الموظف'],
      ...devices.asMap().entries.map((e) {
        final d = e.value;
        return [
          e.key + 1, d.name, d.category.labelAr, d.manufacturer, d.model,
          d.serialNumber, d.condition.labelAr, d.status.labelAr, d.location, d.assignedEmployee ?? '-',
        ];
      }),
    ];

    final cardRows = [
      ['رقم البطاقة', 'الموظف', 'الوظيفة', 'الدائرة', 'عدد المواد', 'الحالة'],
      ...cards.map((c) => [c.cardNumber, c.employeeName, c.jobTitle, c.department, c.items.length, c.status]),
    ];

    final movRows = [
      ['السند', 'النوع', 'الجهاز', 'من', 'إلى', 'التاريخ'],
      ...movements.map((m) => [m.referenceNumber, m.type.labelAr, m.deviceName, m.fromEntity, m.toEntity, m.date]),
    ];

    final tktRows = [
      ['البلاغ', 'الجهاز', 'العطل', 'الأولوية', 'الحالة', 'التاريخ'],
      ...tickets.map((t) => [t.ticketNumber, t.deviceName, t.faultDescription, t.priority.labelAr, t.status.labelAr, t.reportDate]),
    ];

    final updateResponse = await http.post(
      Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$id/values:batchUpdate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'valueInputOption': 'USER_ENTERED',
        'data': [
          {'range': 'الأجهزة!A1', 'values': deviceRows},
          {'range': 'العهدة!A1', 'values': cardRows},
          {'range': 'الحركات!A1', 'values': movRows},
          {'range': 'الصيانة!A1', 'values': tktRows},
        ],
      }),
    );

    if (updateResponse.statusCode < 200 || updateResponse.statusCode >= 300) {
      final err = jsonDecode(updateResponse.body);
      throw Exception(err['error']?['message'] ?? 'فشل تحديث البيانات');
    }

    return SheetsExportResult(spreadsheetId: id, spreadsheetUrl: url);
  }

  String _arabicDate() {
    final now = DateTime.now();
    return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
  }
}
