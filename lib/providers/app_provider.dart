import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/backend_config.dart';
import '../services/firebase_service.dart';
import '../services/catalog_service.dart';
import '../services/excel_service.dart';
import '../services/sheets_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  final BackendConfig _backend = BackendConfig();
  final CatalogService catalog = CatalogService();

  User? currentUser;
  UserRoleType currentRole = UserRoleType.technician;
  String headEmail = FirebaseService.defaultHeadEmail;
  String departmentName = 'دائرة الاتصالات - وزارة الطوارئ وإدارة الكوارث';

  bool isLoading = true;
  bool isSyncing = false;
  bool isOffline = false;
  String activeTab = 'dashboard';

  /// عند true تفتح شاشة الأجهزة نموذج «إضافة جهاز»
  bool requestOpenAddDevice = false;

  void openAddDevice() {
    requestOpenAddDevice = true;
    activeTab = 'devices';
    notifyListeners();
  }

  void clearOpenAddDevice() {
    requestOpenAddDevice = false;
  }

  List<Device> devices = [];
  List<CustodyCard> custodyCards = [];
  List<Movement> movements = [];
  List<MaintenanceTicket> tickets = [];
  List<AuditLog> auditLogs = [];
  List<PhoneDirectoryEntry> phoneDirectory = [];
  List<TelecomNetworkInfo> telecomNetworks = [];
  List<PendingRequest> pendingRequests = [];

  final List<StreamSubscription> _subs = [];

  bool get isLoggedIn => currentUser != null;

  /// رئيس دائرة الاتصالات = مدير النظام
  bool get isHeadOfDept =>
      _backend.isSystemAdmin(currentUser?.email) ||
      _firebase.isHeadOfDept(currentUser?.email, headEmail);

  /// مدير النظام (نفس رئيس الدائرة — صلاحيات كاملة)
  bool get isSystemAdmin => isHeadOfDept;

  BackendType get backendType => _backend.type;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await catalog.load();
    _subs.add(_firebase.authStateChanges.listen((user) async {
      currentUser = user;
      if (user != null) {
        await _loadSettingsAndData();
      } else {
        _clearData();
        isLoading = false;
        notifyListeners();
      }
    }));
  }

  Future<void> _loadSettingsAndData() async {
    isLoading = true;
    notifyListeners();

    try {
      final settings = await _firebase.getSystemSettings();
      headEmail = settings.headEmail;
      departmentName = settings.departmentName;

      if (isHeadOfDept) {
        currentRole = UserRoleType.director;
      }

      // Cancel previous data subscriptions
      for (final s in _subs.skip(1)) {
        s.cancel();
      }
      _subs.removeRange(1, _subs.length);

      _subs.add(_firebase.devicesStream().listen((list) {
        devices = list;
        catalog.syncFromDevices(list);
        notifyListeners();
      }));
      _subs.add(_firebase.custodyCardsStream().listen((list) {
        custodyCards = list;
        notifyListeners();
      }));
      _subs.add(_firebase.movementsStream().listen((list) {
        movements = list;
        notifyListeners();
      }));
      _subs.add(_firebase.ticketsStream().listen((list) {
        tickets = list;
        notifyListeners();
      }));
      _subs.add(_firebase.auditLogsStream().listen((list) {
        auditLogs = list;
        notifyListeners();
      }));
      _subs.add(_firebase.phoneDirectoryStream().listen((list) {
        phoneDirectory = list;
        notifyListeners();
      }));
      _subs.add(_firebase.telecomNetworksStream().listen((list) {
        telecomNetworks = list;
        notifyListeners();
      }));
      _subs.add(_firebase.pendingRequestsStream().listen((list) {
        pendingRequests = list;
        notifyListeners();
      }));
    } catch (e) {
      debugPrint('Load error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _clearData() {
    devices = [];
    custodyCards = [];
    movements = [];
    tickets = [];
    auditLogs = [];
    phoneDirectory = [];
    telecomNetworks = [];
    pendingRequests = [];
  }

  void setActiveTab(String tab) {
    activeTab = tab;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.signInWithGoogle();
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _firebase.signOut();
  }

  // -------------------- CRUD Wrappers --------------------

  Future<String?> saveDevice(Device device) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.saveDevice(device, currentUser!, isHeadOfDept);
      await catalog.learnFromDevice(device);
      return isHeadOfDept ? null : 'تم إرسال الطلب لرئيس الدائرة للاعتماد';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deleteDevice(String id) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    final dev = devices.where((d) => d.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.deleteDevice(id, dev?.name ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveCustodyCard(CustodyCard card) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.saveCustodyCard(card, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال الطلب لرئيس الدائرة للاعتماد';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deleteCustodyCard(String id) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    final card = custodyCards.where((c) => c.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.deleteCustodyCard(id, card?.cardNumber ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveMovement(Movement movement) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.saveMovement(movement, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال الطلب لرئيس الدائرة للاعتماد';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveTicket(MaintenanceTicket ticket) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.saveTicket(ticket, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال الطلب لرئيس الدائرة للاعتماد';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deleteTicket(String id) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    final t = tickets.where((x) => x.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.deleteTicket(id, t?.ticketNumber ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> savePhoneEntry(PhoneDirectoryEntry entry) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.savePhoneEntry(entry, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال الطلب لرئيس الدائرة للاعتماد';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deletePhoneEntry(String id) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    final e = phoneDirectory.where((x) => x.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.deletePhoneEntry(id, e?.employeeName ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveTelecomNetwork(TelecomNetworkInfo network) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.saveTelecomNetwork(network, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال الطلب لرئيس الدائرة للاعتماد';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deleteTelecomNetwork(String id) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    final n = telecomNetworks.where((x) => x.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.deleteTelecomNetwork(id, n?.name ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> approveRequest(PendingRequest req) async {
    if (currentUser == null || !isHeadOfDept) return;
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.approveRequest(req, currentUser!);
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    if (currentUser == null || !isHeadOfDept) return;
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.rejectRequest(requestId, reason, currentUser!);
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> updateHeadEmail(String email) async {
    if (!isHeadOfDept) return;
    await _firebase.updateHeadEmail(email);
    headEmail = email;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }


  // -------------------- تصدير / استيراد --------------------

  final ExcelService _excel = ExcelService();
  final SheetsService _sheets = SheetsService();

  Future<String?> exportDevicesExcel() async {
    try {
      return await _excel.exportDevices(devices);
    } catch (e) {
      return 'خطأ التصدير: $e';
    }
  }

  Future<String?> exportCustodyExcel() async {
    try {
      return await _excel.exportCustodyCards(custodyCards);
    } catch (e) {
      return 'خطأ التصدير: $e';
    }
  }

  Future<String?> exportFullExcel() async {
    try {
      return await _excel.exportFullReport(
        devices: devices,
        cards: custodyCards,
        movements: movements,
        tickets: tickets,
        phones: phoneDirectory,
        networks: telecomNetworks,
      );
    } catch (e) {
      return 'خطأ التصدير: $e';
    }
  }

  Future<ImportResult<Device>> importDevicesExcel() async {
    return _excel.importDevicesFromFile();
  }

  Future<ImportResult<CustodyCard>> importCustodyExcel() async {
    return _excel.importCustodyCardsFromFile();
  }

  Future<SheetsExportResult> exportToGoogleSheets() async {
    return _sheets.exportInventoryToGoogleSheets(
      title: 'جرد الأصول والعهدة - دائرة الاتصالات',
      devices: devices,
      custodyCards: custodyCards,
    );
  }

  Future<SheetsExportResult> exportFullToGoogleSheets() async {
    return _sheets.exportFullReportToSheets(
      devices: devices,
      cards: custodyCards,
      movements: movements,
      tickets: tickets,
    );
  }

}
