import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/catalog_service.dart';
import '../services/excel_service.dart';
import '../services/sheets_service.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final CatalogService catalog = CatalogService();
  final ExcelService _excel = ExcelService();
  final SheetsService _sheets = SheetsService();

  User? currentUser;
  UserRoleType currentRole = UserRoleType.technician;
  String headEmail = '';
  String departmentName = 'دائرة الاتصالات - وزارة الطوارئ وإدارة الكوارث';
  bool isLoading = true;
  bool isSyncing = false;
  bool isOffline = false;
  String? loadError;
  bool _isAdmin = false;
  String activeTab = 'dashboard';
  bool requestOpenAddDevice = false;

  List<Device> devices = [];
  List<CustodyCard> custodyCards = [];
  List<Movement> movements = [];
  List<MaintenanceTicket> tickets = [];
  List<AuditLog> auditLogs = [];
  List<PhoneDirectoryEntry> phoneDirectory = [];
  List<TelecomNetworkInfo> telecomNetworks = [];
  List<Map<String, dynamic>> networkSwitches = [];
  List<PendingRequest> pendingRequests = [];

  StreamSubscription<AuthState>? _authSubscription;
  bool get isLoggedIn => currentUser != null;
  String get currentUserName => currentUser?.userMetadata?['display_name'] as String? ?? currentUser?.email?.split('@').first ?? '';
  bool get isHeadOfDept => _isAdmin;
  bool get isSystemAdmin => _isAdmin;
  bool get isSupabaseBackend => true;

  AppProvider() { _init(); }

  void openAddDevice() { requestOpenAddDevice = true; activeTab = 'devices'; notifyListeners(); }
  void clearOpenAddDevice() { requestOpenAddDevice = false; }
  void setActiveTab(String tab) { activeTab = tab; notifyListeners(); }

  /// Reloads the signed-in user's dashboard data when they pull to refresh.
  Future<void> refreshData() async {
    if (currentUser == null || isLoading || isSyncing) return;
    await _loadSettingsAndData();
  }

  Future<void> _init() async {
    await catalog.load();
    currentUser = _supabase.currentUser;
    _authSubscription = _supabase.authStateChanges.listen((state) async {
      currentUser = state.session?.user;
      if (currentUser == null) {
        _clearData();
        _isAdmin = false;
        isLoading = false;
        notifyListeners();
      } else {
        await _loadSettingsAndData();
      }
    });
    if (currentUser == null) {
      isLoading = false;
      notifyListeners();
    } else {
      await _loadSettingsAndData();
    }
  }

  Future<void> _loadSettingsAndData() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _supabase.currentAppRole(),
        _supabase.isSystemAdmin(),
        _supabase.fetchDevices(),
        _supabase.fetchCustodyCards(),
        _supabase.fetchMovements(),
        _supabase.fetchTickets(),
        _supabase.fetchAuditLogs(),
        _supabase.fetchPhones(),
        _supabase.fetchNetworks(),
        _supabase.fetchPendingRequests(),
      ]);
      final role = results[0] as String?;
      _isAdmin = results[1] as bool;
      currentRole = role == 'primary_admin' || role == 'admin'
          ? UserRoleType.director : UserRoleType.technician;
      devices = results[2] as List<Device>;
      custodyCards = results[3] as List<CustodyCard>;
      movements = results[4] as List<Movement>;
      tickets = results[5] as List<MaintenanceTicket>;
      auditLogs = results[6] as List<AuditLog>;
      phoneDirectory = results[7] as List<PhoneDirectoryEntry>;
      telecomNetworks = results[8] as List<TelecomNetworkInfo>;
      pendingRequests = results[9] as List<PendingRequest>;
      try {
        networkSwitches = await _supabase.fetchNetworkSwitches();
      } catch (e) {
        // A switch-table permission/schema issue must not block the core inventory.
        networkSwitches = [];
        debugPrint('Network switches load error: $e');
      }
      catalog.syncFromDevices(devices);
    } catch (e, st) {
      loadError = 'تعذر تحميل بيانات النظام من Supabase. تحقق من الاتصال وصلاحيات الحساب ثم أعد المحاولة.';
      debugPrint('Supabase load error: $e\n$st');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _clearData() {
    devices = []; custodyCards = []; movements = []; tickets = [];
    auditLogs = []; phoneDirectory = []; telecomNetworks = []; networkSwitches = []; pendingRequests = [];
  }

  Future<void> loginWithEmail(String email, String password) async {
    isSyncing = true; notifyListeners();
    try { await _supabase.signInWithEmail(email.trim(), password); }
    finally { isSyncing = false; notifyListeners(); }
  }

  Future<void> loginWithGoogle() async {
    isSyncing = true; notifyListeners();
    try { await _supabase.signInWithGoogle(); }
    finally { isSyncing = false; notifyListeners(); }
  }

  Future<void> logout() => _supabase.signOut();

  Future<String?> _run(Future<void> Function() action, {String success = 'تم إرسال الطلب لرئيس الدائرة للاعتماد'}) async {
    if (currentUser == null) return 'يجب تسجيل الدخول';
    isSyncing = true; notifyListeners();
    try {
      await action();
      await _loadSettingsAndData();
      return _isAdmin ? null : success;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final details = '${e.message} ${e.details ?? ''}';
        if (details.contains('devices_barcode_unique_nonblank_idx')) {
          return 'خطأ: هذا الباركود مسجل مسبقاً لجهاز آخر.';
        }
        if (details.contains('devices_asset_number_unique_nonblank_idx')) {
          return 'خطأ: رقم الأصل مسجل مسبقاً لجهاز آخر.';
        }
        return 'خطأ: توجد قيمة مكررة. تحقق من رقم الجهاز أو السجل قبل الحفظ.';
      }
      return 'خطأ: ${e.message}';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveDevice(Device d) => _run(() async { await _supabase.saveDevice(d); });
  Future<String?> deleteDevice(String id) {
    final d = devices.where((x) => x.id == id).firstOrNull;
    return _run(() => _supabase.deleteDevice(id, d?.name ?? id), success: 'تم إرسال طلب الحذف لرئيس الدائرة');
  }
  Future<String?> saveCustodyCard(CustodyCard c) => _run(() => _supabase.saveCustodyCard(c));
  Future<String?> deleteCustodyCard(String id) {
    final c = custodyCards.where((x) => x.id == id).firstOrNull;
    return _run(() => _supabase.deleteCustodyCard(id, c?.cardNumber ?? id), success: 'تم إرسال طلب الحذف لرئيس الدائرة');
  }
  Future<String?> saveMovement(Movement m) => _run(() => _supabase.saveMovement(m));
  Future<String?> saveTicket(MaintenanceTicket t) => _run(() => _supabase.saveTicket(t));
  Future<String?> deleteTicket(String id) {
    final t = tickets.where((x) => x.id == id).firstOrNull;
    return _run(() => _supabase.deleteTicket(id, t?.ticketNumber ?? id), success: 'تم إرسال طلب الحذف لرئيس الدائرة');
  }
  Future<String?> savePhoneEntry(PhoneDirectoryEntry e) => _run(() => _supabase.savePhone(e));
  Future<String?> deletePhoneEntry(String id) {
    final e = phoneDirectory.where((x) => x.id == id).firstOrNull;
    return _run(() => _supabase.deletePhone(id, e?.employeeName ?? id), success: 'تم إرسال طلب الحذف لرئيس الدائرة');
  }
  Future<String?> saveTelecomNetwork(TelecomNetworkInfo n) => _run(() => _supabase.saveNetwork(n));
  Future<String?> saveNetworkSwitch(Map<String, dynamic> item) => _run(() => _supabase.saveNetworkSwitch(item));
  Future<String?> deleteNetworkSwitch(String id, String name) => _run(() => _supabase.deleteNetworkSwitch(id, name), success: 'تم إرسال طلب حذف السويتش للاعتماد');
  Future<String?> deleteTelecomNetwork(String id) {
    final n = telecomNetworks.where((x) => x.id == id).firstOrNull;
    return _run(() => _supabase.deleteNetwork(id, n?.name ?? id), success: 'تم إرسال طلب الحذف لرئيس الدائرة');
  }
  Future<void> approveRequest(PendingRequest req) async {
    if (!_isAdmin) throw Exception('صلاحية مدير النظام فقط');
    await _supabase.approveRequest(req); await _loadSettingsAndData();
  }
  Future<void> rejectRequest(String id, String reason) async {
    if (!_isAdmin) throw Exception('صلاحية مدير النظام فقط');
    await _supabase.rejectRequest(id, reason); await _loadSettingsAndData();
  }
  Future<String?> requestAdminHandover({
    required String proposedAdminEmail,
    required String targetProjectRef,
  }) async {
    if (!_isAdmin) return 'هذه العملية متاحة لمدير النظام الحالي فقط';
    try {
      return await _supabase.requestAdminHandover(
        proposedAdminEmail: proposedAdminEmail,
        targetProjectRef: targetProjectRef,
      );
    } catch (e) {
      return 'تعذر إنشاء طلب التسليم: $e';
    }
  }

  Future<void> updateHeadEmail(String email) async {
    throw UnsupportedError('تعيين مدير النظام يتم من صلاحيات Supabase وليس بتغيير البريد من التطبيق.');
  }

  Future<String?> exportDevicesExcel() async {
    try { return await _excel.exportDevices(devices); } catch (e) { return 'خطأ التصدير: $e'; }
  }
  Future<String?> exportCustodyExcel() async {
    try { return await _excel.exportCustodyCards(custodyCards); } catch (e) { return 'خطأ التصدير: $e'; }
  }
  Future<String?> exportFullExcel() async {
    try { return await _excel.exportFullReport(devices: devices, cards: custodyCards, movements: movements, tickets: tickets, phones: phoneDirectory, networks: telecomNetworks); }
    catch (e) { return 'خطأ التصدير: $e'; }
  }
  Future<ImportResult<Device>> importDevicesExcel() => _excel.importDevicesFromFile();
  Future<ImportResult<CustodyCard>> importCustodyExcel() => _excel.importCustodyCardsFromFile();

  Future<SheetsExportResult> exportToGoogleSheets() => _sheets.exportInventoryToGoogleSheets(
    title: 'جرد الأصول والعهدة - دائرة الاتصالات',
    devices: devices,
    custodyCards: custodyCards,
  );

  Future<SheetsExportResult> exportFullToGoogleSheets() => _sheets.exportFullReportToSheets(
    devices: devices,
    cards: custodyCards,
    movements: movements,
    tickets: tickets,
  );

  @override
  void dispose() { _authSubscription?.cancel(); super.dispose(); }
}
