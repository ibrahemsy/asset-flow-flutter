import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/backend_config.dart';
import '../services/supabase_service.dart';
import '../services/catalog_service.dart';
import '../services/excel_service.dart';
import '../services/sheets_service.dart';

/// واجهة مستخدم بسيطة بدل Firebase User للشاشات القديمة
class AppUserView {
  final String? email;
  final String? displayName;
  final String? uid;
  const AppUserView({this.email, this.displayName, this.uid});
}

/// مزوّد الحالة — مسار Supabase فقط (بدون تهيئة Firebase على الويب)
class AppProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final BackendConfig _backend = BackendConfig();
  final CatalogService catalog = CatalogService();

  String? supabaseEmail;
  String? supabaseUid;
  String? supabaseName;

  UserRoleType currentRole = UserRoleType.technician;
  String headEmail = '';
  String departmentName = 'دائرة الاتصالات - وزارة الطوارئ وإدارة الكوارث';

  bool isLoading = true;
  bool isSyncing = false;
  bool isOffline = false;
  String activeTab = 'dashboard';

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
  List<NetworkSwitch> networkSwitches = [];
  List<CustodyCard> custodyCards = [];
  List<Movement> movements = [];
  List<MaintenanceTicket> tickets = [];
  List<AuditLog> auditLogs = [];
  List<PhoneDirectoryEntry> phoneDirectory = [];
  List<TelecomNetworkInfo> telecomNetworks = [];
  List<PendingRequest> pendingRequests = [];

  final List<StreamSubscription> _subs = [];

  bool get isLoggedIn =>
      supabaseEmail != null && supabaseEmail!.isNotEmpty;

  String? get activeEmail => supabaseEmail;

  /// متوافق مع الشاشات التي كانت تستخدم Firebase User
  AppUserView? get currentUser {
    if (!isLoggedIn) return null;
    return AppUserView(
      email: supabaseEmail,
      displayName: (supabaseName != null && supabaseName!.isNotEmpty)
          ? supabaseName
          : (supabaseEmail?.split('@').first ?? 'مستخدم'),
      uid: supabaseUid,
    );
  }

  bool get isHeadOfDept => _backend.isSystemAdmin(activeEmail);

  bool get isSystemAdmin => isHeadOfDept;

  BackendType get backendType => BackendType.supabase;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await catalog.load();
    await _backend.load();
    if (!_backend.isSupabase) {
      await _backend.setBackend(BackendType.supabase);
    }

    try {
      final u = _supabase.currentUser;
      if (u != null) {
        supabaseEmail = u.email;
        supabaseUid = u.id;
        supabaseName = _supabase.userName;
        await _loadSupabaseData();
      } else {
        isLoading = false;
        notifyListeners();
      }

      _subs.add(_supabase.authStateChanges.listen((state) async {
        final user = state.session?.user;
        if (user != null) {
          supabaseEmail = user.email;
          supabaseUid = user.id;
          supabaseName = _supabase.userName;
          await _loadSupabaseData();
        } else {
          supabaseEmail = null;
          supabaseUid = null;
          supabaseName = null;
          _clearData();
          isLoading = false;
          notifyListeners();
        }
      }));
    } catch (e, st) {
      debugPrint('AppProvider init: $e');
      debugPrint('$st');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSupabaseData() async {
    isLoading = true;
    notifyListeners();
    try {
      currentRole =
          isHeadOfDept ? UserRoleType.director : UserRoleType.technician;
      if (_backend.adminEmails.isNotEmpty) {
        headEmail = _backend.adminEmails.first;
      }
      devices = await _supabase.fetchDevices();
      catalog.syncFromDevices(devices);
      custodyCards = await _supabase.fetchCustodyCards();
      movements = await _supabase.fetchMovements();
      tickets = await _supabase.fetchTickets();
      auditLogs = await _supabase.fetchAuditLogs();
      phoneDirectory = await _supabase.fetchPhones();
      telecomNetworks = await _supabase.fetchNetworks();
      pendingRequests = await _supabase.fetchPendingRequests();
      networkSwitches = [];
    } catch (e) {
      debugPrint('Supabase load error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _clearData() {
    currentRole = UserRoleType.technician;
    devices = [];
    networkSwitches = [];
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
      await _supabase.signInWithGoogle();
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    isSyncing = true;
    notifyListeners();
    try {
      final res = await _supabase.signInWithEmail(email, password);
      final u = res.user;
      if (u != null) {
        supabaseEmail = u.email;
        supabaseUid = u.id;
        supabaseName = _supabase.userName;
        await _loadSupabaseData();
      }
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password,
      {String? name}) async {
    isSyncing = true;
    notifyListeners();
    try {
      final res = await _supabase.signUp(email, password, name: name);
      final u = res.user;
      if (u != null) {
        supabaseEmail = u.email;
        supabaseUid = u.id;
        supabaseName =
            name != null && name.isNotEmpty ? name : _supabase.userName;
        await _loadSupabaseData();
      }
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _supabase.signOut();
    supabaseEmail = null;
    supabaseUid = null;
    supabaseName = null;
    _clearData();
    notifyListeners();
  }

  Future<String?> saveNetworkSwitch(NetworkSwitch networkSwitch) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    return 'حفظ السويتش عبر Supabase قيد التوسيع — استخدم الأجهزة/العهدة حالياً';
  }

  Future<String?> saveDevice(Device device) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.saveDevice(device);
      await catalog.learnFromDevice(device);
      await _loadSupabaseData();
      return isHeadOfDept ? null : 'تم إرسال الطلب للاعتماد';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deleteDevice(String id) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final dev = devices.where((d) => d.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.deleteDevice(id, dev?.name ?? id);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveCustodyCard(CustodyCard card) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.saveCustodyCard(card);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deleteCustodyCard(String id) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final card = custodyCards.where((c) => c.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.deleteCustodyCard(id, card?.cardNumber ?? id);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveMovement(Movement movement) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.saveMovement(movement);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveTicket(MaintenanceTicket ticket) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.saveTicket(ticket);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deleteTicket(String id) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final t = tickets.where((x) => x.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.deleteTicket(id, t?.ticketNumber ?? id);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> savePhoneEntry(PhoneDirectoryEntry entry) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.savePhone(entry);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deletePhoneEntry(String id) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final e = phoneDirectory.where((x) => x.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.deletePhone(id, e?.employeeName ?? id);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveTelecomNetwork(TelecomNetworkInfo network) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.saveNetwork(network);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> deleteTelecomNetwork(String id) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final n = telecomNetworks.where((x) => x.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.deleteNetwork(id, n?.name ?? id);
      await _loadSupabaseData();
      return null;
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> approveRequest(PendingRequest req) async {
    if (!isLoggedIn || !isHeadOfDept) return;
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.approveRequest(req);
      await _loadSupabaseData();
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    if (!isLoggedIn || !isHeadOfDept) return;
    isSyncing = true;
    notifyListeners();
    try {
      await _supabase.rejectRequest(requestId, reason);
      await _loadSupabaseData();
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> updateHeadEmail(String email) async {
    if (!isHeadOfDept) return;
    await _backend.addAdminEmail(email);
    headEmail = email;
    notifyListeners();
  }

  // ---- دوال تسليم الإدارة (كانت على Firebase Functions) ----
  // على Supabase تُعرض رسالة توضيحية حتى يُبنى مسار بديل

  Future<void> reauthenticateCurrentUser() async {
    // لا حاجة لإعادة مصادقة Firebase في مسار Supabase
  }

  Future<String> createAdminHandover(String invitedEmail) async {
    throw StateError(
      'تسليم الإدارة عبر Cloud Functions غير مفعّل مع Supabase حالياً. أضف البريد من إعدادات المدير محلياً.',
    );
  }

  Future<Map<String, dynamic>> findMyAdminHandoverInvitation() async {
    return {'found': false};
  }

  Future<void> acceptAdminHandover(String operationId) async {
    throw StateError('غير متاح مع Supabase حالياً');
  }

  Future<void> approveAdminHandover(String operationId) async {
    throw StateError('غير متاح مع Supabase حالياً');
  }

  Future<void> cancelAdminHandover(String operationId) async {
    throw StateError('غير متاح مع Supabase حالياً');
  }

  Future<Map<String, dynamic>> getAdminHandoverStatus(String operationId) async {
    return {'status': 'unavailable'};
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

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
