import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  // ============================================================
  // تصدير Excel
  // ============================================================

  /// تصدير قائمة أجهزة إلى ملف Excel
  Future<String?> exportDevices(List<Device> devices, {String? filename}) async {
    final excel = Excel.createExcel();
    final sheet = excel['سجل الأجهزة'];
    excel.delete('Sheet1');

    // العنوان
    final headers = [
      'م',
      'اسم الجهاز',
      'التصنيف',
      'الشركة المصنعة',
      'الطراز',
      'الرقم التسلسلي',
      'الباركود',
      'رقم العهدة / المالي',
      'المعالج CPU',
      'الذاكرة RAM',
      'التخزين Storage',
      'الحالة الفنية',
      'حالة التواجد',
      'الموقع / القسم',
      'الموظف المسؤول',
      'تاريخ الشراء',
      'المورد',
      'تاريخ التسليم',
      'ملاحظات',
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    for (var i = 0; i < devices.length; i++) {
      final d = devices[i];
      final row = i + 1;
      final values = [
        i + 1,
        d.name,
        d.category.labelAr,
        d.manufacturer,
        d.model,
        d.serialNumber,
        d.barcode,
        d.assetNumber,
        d.cpu ?? '',
        d.ram ?? '',
        d.storage ?? '',
        d.condition.labelAr,
        d.status.labelAr,
        d.location,
        d.assignedEmployee ?? '',
        d.purchaseDate,
        d.supplier,
        d.deliveryDate ?? '',
        d.notes ?? '',
      ];
      for (var c = 0; c < values.length; c++) {
        final v = values[c];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row)).value =
            v is int ? IntCellValue(v) : TextCellValue(v.toString());
      }
    }

    return _saveAndShare(excel, filename ?? 'تقرير_الأجهزة_${_dateStamp()}.xlsx');
  }

  /// تصدير بطاقات العهدة
  Future<String?> exportCustodyCards(List<CustodyCard> cards, {String? filename}) async {
    final excel = Excel.createExcel();
    final sheet = excel['بطاقات العهدة'];
    excel.delete('Sheet1');

    final headers = [
      'رقم البطاقة',
      'اسم الموظف',
      'الصفة الوظيفية',
      'المديرية',
      'الدائرة',
      'الشعبة',
      'المكتب',
      'مركز العمل',
      'تاريخ الإنشاء',
      'عدد المواد',
      'الحالة',
      'المصادقة الإدارية',
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    for (var i = 0; i < cards.length; i++) {
      final c = cards[i];
      final row = i + 1;
      final values = [
        c.cardNumber,
        c.employeeName,
        c.jobTitle,
        c.directorate,
        c.department,
        c.division,
        c.officeOrCenter,
        c.workCenter,
        c.creationDate,
        c.items.length.toString(),
        c.status == 'active' ? 'نشطة' : (c.status == 'archived' ? 'مؤرشفة' : c.status),
        c.adminEndorsement,
      ];
      for (var col = 0; col < values.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
            TextCellValue(values[col]);
      }
    }

    // ورقة تفاصيل المواد
    final itemsSheet = excel['تفاصيل مواد العهدة'];
    final itemHeaders = [
      'رقم البطاقة',
      'اسم الموظف',
      'م',
      'اسم المادة',
      'الوصف',
      'الوحدة',
      'الكمية',
      'الرقم التسلسلي',
      'الباركود',
      'رمز المادة',
      'الرصيد',
      'ملاحظات',
    ];
    for (var i = 0; i < itemHeaders.length; i++) {
      itemsSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(itemHeaders[i]);
    }
    var itemRow = 1;
    for (final c in cards) {
      for (final item in c.items) {
        final values = [
          c.cardNumber,
          c.employeeName,
          item.no.toString(),
          item.name,
          item.description,
          item.unit,
          item.quantity.toString(),
          item.serialNumber,
          item.barcode,
          item.itemCode,
          item.balance.toString(),
          item.notes,
        ];
        for (var col = 0; col < values.length; col++) {
          itemsSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: itemRow)).value =
              TextCellValue(values[col]);
        }
        itemRow++;
      }
    }

    return _saveAndShare(excel, filename ?? 'تقرير_بطاقات_العهدة_${_dateStamp()}.xlsx');
  }

  /// تصدير الحركات
  Future<String?> exportMovements(List<Movement> movements, {String? filename}) async {
    final excel = Excel.createExcel();
    final sheet = excel['سجل الحركات'];
    excel.delete('Sheet1');

    final headers = [
      'رقم السند',
      'نوع الحركة',
      'اسم الجهاز',
      'الرقم التسلسلي',
      'من',
      'إلى',
      'المنفذ',
      'التاريخ',
      'السبب',
      'ملاحظات',
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    for (var i = 0; i < movements.length; i++) {
      final m = movements[i];
      final values = [
        m.referenceNumber,
        m.type.labelAr,
        m.deviceName,
        m.serialNumber,
        m.fromEntity,
        m.toEntity,
        m.executorName,
        m.date,
        m.reason,
        m.notes ?? '',
      ];
      for (var c = 0; c < values.length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value =
            TextCellValue(values[c]);
      }
    }

    return _saveAndShare(excel, filename ?? 'تقرير_الحركات_${_dateStamp()}.xlsx');
  }

  /// تصدير بلاغات الصيانة
  Future<String?> exportTickets(List<MaintenanceTicket> tickets, {String? filename}) async {
    final excel = Excel.createExcel();
    final sheet = excel['بلاغات الصيانة'];
    excel.delete('Sheet1');

    final headers = [
      'رقم البلاغ',
      'اسم الجهاز',
      'الرقم التسلسلي',
      'وصف العطل',
      'القسم / المكتب',
      'تاريخ البلاغ',
      'الأولوية',
      'الفني المكلف',
      'الإجراءات',
      'قطع الغيار',
      'تاريخ الإصلاح',
      'الحالة',
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    for (var i = 0; i < tickets.length; i++) {
      final t = tickets[i];
      final values = [
        t.ticketNumber,
        t.deviceName,
        t.serialNumber ?? '',
        t.faultDescription,
        t.stationOrDept,
        t.reportDate,
        t.priority.labelAr,
        t.assignedTech,
        t.actionsTaken,
        t.sparePartsUsed,
        t.resolutionDate ?? '',
        t.status.labelAr,
      ];
      for (var c = 0; c < values.length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value =
            TextCellValue(values[c]);
      }
    }

    return _saveAndShare(excel, filename ?? 'تقرير_الصيانة_${_dateStamp()}.xlsx');
  }

  /// تصدير تقرير شامل (عدة أوراق)
  Future<String?> exportFullReport({
    required List<Device> devices,
    required List<CustodyCard> cards,
    required List<Movement> movements,
    required List<MaintenanceTicket> tickets,
    required List<PhoneDirectoryEntry> phones,
    required List<TelecomNetworkInfo> networks,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // --- الأجهزة ---
    final devSheet = excel['الأجهزة'];
    final devHeaders = [
      'م', 'اسم الجهاز', 'التصنيف', 'الشركة', 'الطراز', 'الرقم التسلسلي',
      'رقم العهدة', 'الحالة الفنية', 'حالة التواجد', 'الموقع', 'الموظف', 'ملاحظات',
    ];
    for (var i = 0; i < devHeaders.length; i++) {
      devSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(devHeaders[i]);
    }
    for (var i = 0; i < devices.length; i++) {
      final d = devices[i];
      final vals = [
        '${i + 1}', d.name, d.category.labelAr, d.manufacturer, d.model,
        d.serialNumber, d.assetNumber, d.condition.labelAr, d.status.labelAr,
        d.location, d.assignedEmployee ?? '', d.notes ?? '',
      ];
      for (var c = 0; c < vals.length; c++) {
        devSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value =
            TextCellValue(vals[c]);
      }
    }

    // --- العهدة ---
    final cardSheet = excel['بطاقات العهدة'];
    final cardHeaders = [
      'رقم البطاقة', 'اسم الموظف', 'الوظيفة', 'الدائرة', 'الشعبة',
      'تاريخ الإنشاء', 'عدد المواد', 'الحالة',
    ];
    for (var i = 0; i < cardHeaders.length; i++) {
      cardSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(cardHeaders[i]);
    }
    for (var i = 0; i < cards.length; i++) {
      final c = cards[i];
      final vals = [
        c.cardNumber, c.employeeName, c.jobTitle, c.department, c.division,
        c.creationDate, '${c.items.length}', c.status,
      ];
      for (var col = 0; col < vals.length; col++) {
        cardSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1)).value =
            TextCellValue(vals[col]);
      }
    }

    // --- الحركات ---
    final movSheet = excel['الحركات'];
    final movHeaders = ['رقم السند', 'النوع', 'الجهاز', 'من', 'إلى', 'التاريخ', 'السبب'];
    for (var i = 0; i < movHeaders.length; i++) {
      movSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(movHeaders[i]);
    }
    for (var i = 0; i < movements.length; i++) {
      final m = movements[i];
      final vals = [m.referenceNumber, m.type.labelAr, m.deviceName, m.fromEntity, m.toEntity, m.date, m.reason];
      for (var c = 0; c < vals.length; c++) {
        movSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value =
            TextCellValue(vals[c]);
      }
    }

    // --- الصيانة ---
    final tktSheet = excel['الصيانة'];
    final tktHeaders = ['رقم البلاغ', 'الجهاز', 'العطل', 'الأولوية', 'الحالة', 'التاريخ'];
    for (var i = 0; i < tktHeaders.length; i++) {
      tktSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(tktHeaders[i]);
    }
    for (var i = 0; i < tickets.length; i++) {
      final t = tickets[i];
      final vals = [t.ticketNumber, t.deviceName, t.faultDescription, t.priority.labelAr, t.status.labelAr, t.reportDate];
      for (var c = 0; c < vals.length; c++) {
        tktSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value =
            TextCellValue(vals[c]);
      }
    }

    // --- الهواتف ---
    final phoneSheet = excel['دليل الهواتف'];
    final phoneHeaders = ['الرقم', 'الموظف', 'القسم', 'المكتب', 'منفذ PBX', 'الحالة'];
    for (var i = 0; i < phoneHeaders.length; i++) {
      phoneSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(phoneHeaders[i]);
    }
    for (var i = 0; i < phones.length; i++) {
      final p = phones[i];
      final vals = [p.phoneNumber, p.employeeName, p.department, p.officeLocation, p.pbxPortNumber, p.status];
      for (var c = 0; c < vals.length; c++) {
        phoneSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value =
            TextCellValue(vals[c]);
      }
    }

    // --- الشبكات ---
    final netSheet = excel['الشبكات'];
    final netHeaders = ['الاسم', 'النوع', 'نطاق IP', 'البوابة', 'الموقع', 'الحالة'];
    for (var i = 0; i < netHeaders.length; i++) {
      netSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(netHeaders[i]);
    }
    for (var i = 0; i < networks.length; i++) {
      final n = networks[i];
      final vals = [n.name, n.type, n.ipRange ?? '', n.gateway ?? '', n.location, n.status];
      for (var c = 0; c < vals.length; c++) {
        netSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value =
            TextCellValue(vals[c]);
      }
    }

    return _saveAndShare(excel, 'تقرير_شامل_دائرة_الاتصالات_${_dateStamp()}.xlsx');
  }

  // ============================================================
  // استيراد Excel
  // ============================================================

  /// اختيار ملف Excel واستيراد أجهزة منه
  Future<ImportResult<Device>> importDevicesFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return ImportResult(success: false, message: 'لم يتم اختيار ملف', items: []);
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      return ImportResult(success: false, message: 'تعذر قراءة الملف', items: []);
    }

    return importDevicesFromBytes(bytes);
  }

  /// استيراد أجهزة من bytes
  ImportResult<Device> importDevicesFromBytes(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return ImportResult(success: false, message: 'الملف فارغ أو غير صالح', items: []);
      }

      final sheet = excel.tables.values.first;
      if (sheet == null || sheet.maxRows < 2) {
        return ImportResult(success: false, message: 'لا توجد بيانات في الملف', items: []);
      }

      // قراءة الصف الأول كعناوين
      final headerRow = sheet.rows.first;
      final headerMap = <String, int>{};
      for (var i = 0; i < headerRow.length; i++) {
        final val = _cellStr(headerRow[i]).trim().toLowerCase();
        if (val.isNotEmpty) headerMap[val] = i;
      }

      // البحث عن أعمدة معروفة (عربي أو إنجليزي)
      int? col(List<String> names) {
        for (final n in names) {
          if (headerMap.containsKey(n.toLowerCase())) return headerMap[n.toLowerCase()];
        }
        // بحث جزئي
        for (final entry in headerMap.entries) {
          for (final n in names) {
            if (entry.key.contains(n.toLowerCase()) || n.toLowerCase().contains(entry.key)) {
              return entry.value;
            }
          }
        }
        return null;
      }

      final nameCol = col(['اسم الجهاز', 'name', 'الجهاز', 'التجهيز']);
      final serialCol = col(['الرقم التسلسلي', 'serial', 'serialnumber', 'سيريال']);
      final manufacturerCol = col(['الشركة المصنعة', 'الشركة', 'manufacturer', 'المصنع']);
      final modelCol = col(['الطراز', 'model', 'الموديل']);
      final barcodeCol = col(['الباركود', 'barcode', 'qr']);
      final assetCol = col(['رقم العهدة', 'رقم العهدة / المالي', 'asset', 'assetnumber', 'المالي']);
      final locationCol = col(['الموقع', 'الموقع / القسم', 'location', 'مكان التواجد']);
      final employeeCol = col(['الموظف', 'الموظف المسؤول', 'الموظف المستلم', 'employee', 'assigned']);
      final notesCol = col(['ملاحظات', 'notes']);
      final categoryCol = col(['التصنيف', 'النوع', 'category', 'type']);
      final conditionCol = col(['الحالة الفنية', 'condition']);
      final statusCol = col(['حالة التواجد', 'status', 'الحالة']);
      final supplierCol = col(['المورد', 'supplier']);
      final purchaseCol = col(['تاريخ الشراء', 'تاريخ التوريد', 'purchase', 'purchasedate']);

      if (nameCol == null && serialCol == null) {
        return ImportResult(
          success: false,
          message: 'لم يتم العثور على أعمدة الاسم أو الرقم التسلسلي في الملف',
          items: [],
        );
      }

      final devices = <Device>[];
      final now = DateTime.now().toIso8601String();
      var skipped = 0;

      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        final name = nameCol != null ? _cellStr(row.length > nameCol ? row[nameCol] : null) : '';
        final serial = serialCol != null ? _cellStr(row.length > serialCol ? row[serialCol] : null) : '';

        if (name.isEmpty && serial.isEmpty) {
          skipped++;
          continue;
        }

        final categoryStr = categoryCol != null ? _cellStr(row.length > categoryCol ? row[categoryCol] : null) : '';
        final conditionStr = conditionCol != null ? _cellStr(row.length > conditionCol ? row[conditionCol] : null) : '';
        final statusStr = statusCol != null ? _cellStr(row.length > statusCol ? row[statusCol] : null) : '';

        devices.add(Device(
          id: const Uuid().v4(),
          name: name.isEmpty ? 'جهاز مستورد ${r}' : name,
          category: _parseCategory(categoryStr),
          manufacturer: manufacturerCol != null ? _cellStr(row.length > manufacturerCol ? row[manufacturerCol] : null) : '',
          model: modelCol != null ? _cellStr(row.length > modelCol ? row[modelCol] : null) : '',
          serialNumber: serial.isEmpty ? 'IMP-${DateTime.now().millisecondsSinceEpoch}-$r' : serial,
          barcode: barcodeCol != null ? _cellStr(row.length > barcodeCol ? row[barcodeCol] : null) : '',
          assetNumber: assetCol != null ? _cellStr(row.length > assetCol ? row[assetCol] : null) : '',
          purchaseDate: purchaseCol != null ? _cellStr(row.length > purchaseCol ? row[purchaseCol] : null) : now.split('T').first,
          supplier: supplierCol != null ? _cellStr(row.length > supplierCol ? row[supplierCol] : null) : '',
          condition: _parseCondition(conditionStr),
          status: _parseStatus(statusStr),
          location: locationCol != null ? _cellStr(row.length > locationCol ? row[locationCol] : null) : '',
          assignedEmployee: employeeCol != null ? _cellStr(row.length > employeeCol ? row[employeeCol] : null) : null,
          notes: notesCol != null ? _cellStr(row.length > notesCol ? row[notesCol] : null) : null,
          attachments: [],
          createdAt: now,
          updatedAt: now,
        ));
      }

      if (devices.isEmpty) {
        return ImportResult(success: false, message: 'لم يتم العثور على صفوف بيانات صالحة', items: []);
      }

      return ImportResult(
        success: true,
        message: 'تم استيراد ${devices.length} جهاز${skipped > 0 ? ' (تم تجاهل $skipped صف فارغ)' : ''}',
        items: devices,
      );
    } catch (e) {
      return ImportResult(success: false, message: 'خطأ في قراءة الملف: $e', items: []);
    }
  }

  /// استيراد بطاقات عهدة (بنية مبسطة)
  Future<ImportResult<CustodyCard>> importCustodyCardsFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return ImportResult(success: false, message: 'لم يتم اختيار ملف', items: []);
    }
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      return ImportResult(success: false, message: 'تعذر قراءة الملف', items: []);
    }

    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      if (sheet == null || sheet.maxRows < 2) {
        return ImportResult(success: false, message: 'لا توجد بيانات', items: []);
      }

      final headerRow = sheet.rows.first;
      final headerMap = <String, int>{};
      for (var i = 0; i < headerRow.length; i++) {
        final val = _cellStr(headerRow[i]).trim().toLowerCase();
        if (val.isNotEmpty) headerMap[val] = i;
      }

      int? col(List<String> names) {
        for (final n in names) {
          if (headerMap.containsKey(n.toLowerCase())) return headerMap[n.toLowerCase()];
        }
        for (final entry in headerMap.entries) {
          for (final n in names) {
            if (entry.key.contains(n.toLowerCase())) return entry.value;
          }
        }
        return null;
      }

      final cardNoCol = col(['رقم البطاقة', 'cardnumber', 'البطاقة']);
      final nameCol = col(['اسم الموظف', 'الاسم', 'employee', 'الاسم الثلاثي']);
      final jobCol = col(['الصفة الوظيفية', 'الوظيفة', 'jobtitle', 'الوظيفة']);
      final deptCol = col(['الدائرة', 'department']);
      final divisionCol = col(['الشعبة', 'division']);
      final dateCol = col(['تاريخ الإنشاء', 'التاريخ', 'creationdate', 'date']);

      final cards = <CustodyCard>[];
      final now = DateTime.now().toIso8601String();

      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.rows[r];
        final cardNo = cardNoCol != null ? _cellStr(row.length > cardNoCol ? row[cardNoCol] : null) : '';
        final empName = nameCol != null ? _cellStr(row.length > nameCol ? row[nameCol] : null) : '';
        if (cardNo.isEmpty && empName.isEmpty) continue;

        cards.add(CustodyCard(
          id: const Uuid().v4(),
          cardNumber: cardNo.isEmpty ? 'C-${DateTime.now().millisecondsSinceEpoch}-$r' : cardNo,
          employeeName: empName.isEmpty ? 'موظف مستورد' : empName,
          jobTitle: jobCol != null ? _cellStr(row.length > jobCol ? row[jobCol] : null) : '',
          directorate: 'وزارة الطوارئ وإدارة الكوارث',
          workCenter: '',
          department: deptCol != null ? _cellStr(row.length > deptCol ? row[deptCol] : null) : 'دائرة الاتصالات',
          division: divisionCol != null ? _cellStr(row.length > divisionCol ? row[divisionCol] : null) : '',
          officeOrCenter: '',
          creationDate: dateCol != null ? _cellStr(row.length > dateCol ? row[dateCol] : null) : now.split('T').first,
          items: [],
          employeeSignature: '',
          deliveryOfficerSignature: '',
          deptHeadSignature: '',
          warehouseKeeperSignature: '',
          adminEndorsement: '',
          endorsementDate: '',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ));
      }

      return ImportResult(
        success: cards.isNotEmpty,
        message: cards.isEmpty ? 'لم يتم العثور على بيانات' : 'تم استيراد ${cards.length} بطاقة عهدة',
        items: cards,
      );
    } catch (e) {
      return ImportResult(success: false, message: 'خطأ: $e', items: []);
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  String _cellStr(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final v = cell.value;
    if (v is TextCellValue) return _spanText(v.value);
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    if (v is DateCellValue) {
      return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    }
    return v.toString();
  }

  String _spanText(TextSpan span) {
    final buffer = StringBuffer(span.text ?? '');
    for (final child in span.children ?? const <TextSpan>[]) {
      buffer.write(_spanText(child));
    }
    return buffer.toString();
  }

  DeviceCategory _parseCategory(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('مكتبي') || lower.contains('desktop')) return DeviceCategory.desktop;
    if (lower.contains('محمول') || lower.contains('laptop')) return DeviceCategory.laptop;
    if (lower.contains('شاشة') || lower.contains('monitor')) return DeviceCategory.monitor;
    if (lower.contains('طابعة') || lower.contains('printer')) return DeviceCategory.printer;
    if (lower.contains('ماسح') || lower.contains('scanner')) return DeviceCategory.scanner;
    if (lower.contains('ups') || lower.contains('طاقة')) return DeviceCategory.ups;
    if (lower.contains('router') || lower.contains('توجيه')) return DeviceCategory.router;
    if (lower.contains('switch') || lower.contains('محول')) return DeviceCategory.switchDevice;
    if (lower.contains('access') || lower.contains('لاسلكي') || lower.contains('نقطة')) return DeviceCategory.accessPoint;
    if (lower.contains('هاتف') || lower.contains('phone') || lower.contains('telephony')) return DeviceCategory.telephony;
    if (lower.contains('مودم') || lower.contains('modem')) return DeviceCategory.modem;
    if (lower.contains('كابل') || lower.contains('fiber') || lower.contains('ألياف')) return DeviceCategory.cablesFiber;
    return DeviceCategory.other;
  }

  DeviceCondition _parseCondition(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('ممتاز') || lower.contains('excellent')) return DeviceCondition.excellent;
    if (lower.contains('جيد') || lower.contains('good')) return DeviceCondition.good;
    if (lower.contains('صيانة') || lower.contains('maintenance')) return DeviceCondition.needsMaintenance;
    if (lower.contains('معطل') || lower.contains('defective')) return DeviceCondition.defective;
    if (lower.contains('خارج') || lower.contains('out')) return DeviceCondition.outOfService;
    return DeviceCondition.good;
  }

  DeviceStatus _parseStatus(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('مستودع') || lower.contains('warehouse')) return DeviceStatus.inWarehouse;
    if (lower.contains('موظف') || lower.contains('employee')) return DeviceStatus.assignedEmployee;
    if (lower.contains('قسم') || lower.contains('department')) return DeviceStatus.assignedDepartment;
    if (lower.contains('صيانة') || lower.contains('maintenance')) return DeviceStatus.inMaintenance;
    if (lower.contains('خارج') || lower.contains('decommission')) return DeviceStatus.decommissioned;
    return DeviceStatus.inWarehouse;
  }

  String _dateStamp() => DateTime.now().toIso8601String().split('T').first;

  Future<String?> _saveAndShare(Excel excel, String filename) async {
    final bytes = excel.encode();
    if (bytes == null) return null;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$filename';
    final file = File(path);
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(path)],
      subject: filename,
      text: 'تقرير دائرة الاتصالات - وزارة الطوارئ وإدارة الكوارث',
    );

    return path;
  }
}

class ImportResult<T> {
  final bool success;
  final String message;
  final List<T> items;

  ImportResult({
    required this.success,
    required this.message,
    required this.items,
  });
}
