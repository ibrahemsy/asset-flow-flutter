import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/backend_config.dart';
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';
import '../services/catalog_service.dart';
import '../services/excel_service.dart';
import '../services/sheets_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  final SupabaseService _supabase = SupabaseService();
  final BackendConfig _backend = BackendConfig();
  final CatalogService catalog = CatalogService();

  User? currentUser;
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

  bool get isLoggedIn => _backend.isSupabase
      ? (supabaseEmail != null && supabaseEmail!.isNotEmpty)
      : currentUser != null;

  String? get activeEmail =>
      _backend.isSupabase ? supabaseEmail : currentUser?.email;

  bool get isHeadOfDept => _backend.isSystemAdmin(activeEmail);

  bool get isSystemAdmin => isHeadOfDept;

  BackendType get backendType => _backend.type;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await catalog.load();
    await _backend.load();

    if (_backend.isSupabase) {
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
    } else {
      _subs.add(_firebase.authStateChanges.listen((user) async {
        currentUser = user;
        if (user != null) {
          await _loadFirebaseData();
        } else {
          _clearData();
          isLoading = false;
          notifyListeners();
        }
      }));
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

  Future<void> _loadFirebaseData() async {
    isLoading = true;
    notifyListeners();

    try {
      final settings = await _firebase.getSystemSettings();
      headEmail = settings.headEmail;
      departmentName = settings.departmentName;

      currentRole =
          isHeadOfDept ? UserRoleType.director : UserRoleType.technician;

      for (final s in _subs.skip(1)) {
        s.cancel();
      }
      if (_subs.length > 1) {
        _subs.removeRange(1, _subs.length);
      }

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
      _subs.add(_firebase.networkSwitchesStream().listen((list) {
        networkSwitches = list;
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
      if (_backend.isSupabase) {
        await _supabase.signInWithGoogle();
      } else {
        await _firebase.signInWithGoogle();
      }
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
      final res =
          await _supabase.signUp(email, password, name: name);
      final u = res.user;
      if (u != null) {
        supabaseEmail = u.email;
        supabaseUid = u.id;
        supabaseName = name?.isNotEmpty == true ? name : _supabase.userName;
        await _loadSupabaseData();
      }
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_backend.isSupabase) {
      await _supabase.signOut();
      supabaseEmail = null;
      supabaseUid = null;
      supabaseName = null;
      _clearData();
      notifyListeners();
    } else {
      await _firebase.signOut();
    }
  }

  Future<String?> saveNetworkSwitch(NetworkSwitch networkSwitch) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    if (_backend.isSupabase) {
      return 'حفظ السويتش عبر Supabase قيد التوسيع — استخدم الأجهزة/العهدة حالياً';
    }
    if (currentUser == null) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      await _firebase.saveNetworkSwitch(
          networkSwitch, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب السويتش لرئيس الدائرة للاعتماد';
    } catch (e) {
      return 'خطأ: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> saveDevice(Device device) async {
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      if (_backend.isSupabase) {
        await _supabase.saveDevice(device);
        await catalog.learnFromDevice(device);
        await _loadSupabaseData();
        return isHeadOfDept ? null : 'تم إرسال الطلب للاعتماد';
      }
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
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final dev = devices.where((d) => d.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      if (_backend.isSupabase) {
        await _supabase.deleteDevice(id, dev?.name ?? id);
        await _loadSupabaseData();
        return null;
      }
      await _firebase.deleteDevice(
          id, dev?.name ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
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
      if (_backend.isSupabase) {
        await _supabase.saveCustodyCard(card);
        await _loadSupabaseData();
        return null;
      }
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
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final card = custodyCards.where((c) => c.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      if (_backend.isSupabase) {
        await _supabase.deleteCustodyCard(id, card?.cardNumber ?? id);
        await _loadSupabaseData();
        return null;
      }
      await _firebase.deleteCustodyCard(
          id, card?.cardNumber ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
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
      if (_backend.isSupabase) {
        await _supabase.saveMovement(movement);
        await _loadSupabaseData();
        return null;
      }
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
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    isSyncing = true;
    notifyListeners();
    try {
      if (_backend.isSupabase) {
        await _supabase.saveTicket(ticket);
        await _loadSupabaseData();
        return null;
      }
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
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final t = tickets.where((x) => x.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      if (_backend.isSupabase) {
        await _supabase.deleteTicket(id, t?.ticketNumber ?? id);
        await _loadSupabaseData();
        return null;
      }
      await _firebase.deleteTicket(
          id, t?.ticketNumber ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
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
      if (_backend.isSupabase) {
        await _supabase.savePhone(entry);
        await _loadSupabaseData();
        return null;
      }
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
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final e = phoneDirectory.where((x) => x.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      if (_backend.isSupabase) {
        await _supabase.deletePhone(id, e?.employeeName ?? id);
        await _loadSupabaseData();
        return null;
      }
      await _firebase.deletePhoneEntry(
          id, e?.employeeName ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
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
      if (_backend.isSupabase) {
        await _supabase.saveNetwork(network);
        await _loadSupabaseData();
        return null;
      }
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
    if (!isLoggedIn) return 'يجب تسجيل الدخول';
    final n = telecomNetworks.where((x) => x.id == id).firstOrNull;
    isSyncing = true;
    notifyListeners();
    try {
      if (_backend.isSupabase) {
        await _supabase.deleteNetwork(id, n?.name ?? id);
        await _loadSupabaseData();
        return null;
      }
      await _firebase.deleteTelecomNetwork(
          id, n?.name ?? id, currentUser!, isHeadOfDept);
      return isHeadOfDept ? null : 'تم إرسال طلب الحذف لرئيس الدائرة';
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
      if (_backend.isSupabase) {
        await _supabase.approveRequest(req);
        await _loadSupabaseData();
      } else if (currentUser != null) {
        await _firebase.approveRequest(req, currentUser!);
      }
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
      if (_backend.isSupabase) {
        await _supabase.rejectRequest(requestId, reason);
        await _loadSupabaseData();
      } else if (currentUser != null) {
        await _firebase.rejectRequest(requestId, reason, currentUser!);
      }
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> reauthenticateCurrentUser() {
    return _firebase.reauthenticateCurrentUser();
  }

  Future<String> createAdminHandover(String invitedEmail) async {
    if (!isHeadOfDept) {
      throw StateError('هذه العملية متاحة للمدير الحالي فقط.');
    }
    return _firebase.createAdminHandover(invitedEmail);
  }

  Future<Map<String, dynamic>> findMyAdminHandoverInvitation() {
    return _firebase.findMyAdminHandoverInvitation();
  }

  Future<void> acceptAdminHandover(String operationId) async {
    await _firebase.acceptAdminHandover(operationId);
  }

  Future<void> approveAdminHandover(String operationId) async {
    if (!isHeadOfDept) {
      throw StateError('هذه العملية متاحة للمدير الحالي فقط.');
    }
    await _firebase.approveAdminHandover(operationId);
    headEmail = '';
    currentRole = UserRoleType.technician;
    notifyListeners();
  }

  Future<void> cancelAdminHandover(String operationId) async {
    if (!isHeadOfDept) {
      throw StateError('هذه العملية متاحة للمدير الحالي فقط.');
    }
    await _firebase.cancelAdminHandover(operationId);
  }

  Future<Map<String, dynamic>> getAdminHandoverStatus(String operationId) {
    return _firebase.getAdminHandoverStatus(operationId);
  }

  Future<void> updateHeadEmail(String email) async {
    if (!isHeadOfDept) return;
    await _backend.addAdminEmail(email);
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
