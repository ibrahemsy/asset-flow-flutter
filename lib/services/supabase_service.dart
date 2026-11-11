import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'backend_config.dart';

/// خدمة Supabase — نفس منطق Firebase (جداول + اعتماد من مدير النظام)
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isInitialized {
    try {
      // ignore: unnecessary_null_comparison
      return Supabase.instance.client != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> initialize() async {
    final cfg = BackendConfig();
    await cfg.load();
    if (!cfg.supabaseConfigured) {
      throw Exception('لم يتم ضبط رابط ومفتاح Supabase');
    }
    await Supabase.initialize(
      url: cfg.supabaseUrl,
      anonKey: cfg.supabaseAnonKey,
    );
  }

  // -------------------- Auth --------------------

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, {String? name}) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': name},
    );
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: null,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? get userEmail => currentUser?.email;
  String get userName =>
      currentUser?.userMetadata?['display_name'] as String? ??
      currentUser?.email?.split('@').first ??
      'مستخدم';

  bool isSystemAdmin() {
    return BackendConfig().isSystemAdmin(userEmail);
  }

  // -------------------- Helpers --------------------

  Future<void> _logAudit({
    required String action,
    required String entity,
    required String entityId,
    required String details,
  }) async {
    try {
      await _client.from('audit_logs').insert({
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
        'action': action,
        'entity': entity,
        'entity_id': entityId,
        'user_name': userName,
        'user_email': userEmail ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'details': details,
      });
    } catch (_) {}
  }

  /// إذا كان مدير النظام → كتابة مباشرة، وإلا → طلب اعتماد
  Future<void> submitOrCommit({
    required String table,
    required String actionType,
    required String title,
    required String details,
    required Map<String, dynamic> payload,
    String? targetDocId,
  }) async {
    final admin = isSystemAdmin();
    if (admin) {
      final id = payload['id'] ?? targetDocId;
      if (actionType.startsWith('delete') && id != null) {
        await _client.from(table).delete().eq('id', id);
      } else {
        await _client.from(table).upsert(payload);
      }
      await _logAudit(
        action: title,
        entity: table,
        entityId: '${payload['id'] ?? targetDocId ?? ''}',
        details: details,
      );
    } else {
      final reqId = 'req_${DateTime.now().millisecondsSinceEpoch}';
      await _client.from('pending_requests').insert({
        'id': reqId,
        'action_type': actionType,
        'title': title,
        'details': details,
        'requester_uid': currentUser?.id ?? '',
        'requester_email': userEmail ?? '',
        'requester_name': userName,
        'payload': payload,
        'target_collection': table,
        'target_doc_id': payload['id'] ?? targetDocId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // -------------------- Streams / Lists --------------------

  Future<List<Device>> fetchDevices() async {
    final rows = await _client.from('devices').select();
    return (rows as List)
        .map((r) => Device.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
        .toList();
  }

  Future<List<CustodyCard>> fetchCustodyCards() async {
    final rows = await _client.from('custody_cards').select();
    return (rows as List)
        .map((r) => CustodyCard.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
        .toList();
  }

  Future<List<Movement>> fetchMovements() async {
    final rows = await _client.from('movements').select();
    return (rows as List)
        .map((r) => Movement.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
        .toList();
  }

  Future<List<MaintenanceTicket>> fetchTickets() async {
    final rows = await _client.from('maintenance_tickets').select();
    return (rows as List)
        .map((r) => MaintenanceTicket.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
        .toList();
  }

  Future<List<AuditLog>> fetchAuditLogs() async {
    final rows =
        await _client.from('audit_logs').select().order('timestamp', ascending: false);
    return (rows as List)
        .map((r) => AuditLog.fromMap({
              ...Map<String, dynamic>.from(r),
              'entityId': r['entity_id'],
              'userName': r['user_name'],
              'userEmail': r['user_email'],
            }, r['id'] as String))
        .toList();
  }

  Future<List<PhoneDirectoryEntry>> fetchPhones() async {
    final rows = await _client.from('phone_directory').select();
    return (rows as List)
        .map((r) =>
            PhoneDirectoryEntry.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
        .toList();
  }

  Future<List<TelecomNetworkInfo>> fetchNetworks() async {
    final rows = await _client.from('telecom_networks').select();
    return (rows as List)
        .map((r) =>
            TelecomNetworkInfo.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
        .toList();
  }

  Future<List<PendingRequest>> fetchPendingRequests() async {
    final rows =
        await _client.from('pending_requests').select().order('created_at', ascending: false);
    return (rows as List).map((r) {
      final m = Map<String, dynamic>.from(r);
      return PendingRequest.fromMap({
        'actionType': m['action_type'],
        'title': m['title'],
        'details': m['details'],
        'requesterUid': m['requester_uid'],
        'requesterEmail': m['requester_email'],
        'requesterName': m['requester_name'],
        'payload': m['payload'] is Map ? Map<String, dynamic>.from(m['payload']) : {},
        'targetCollection': m['target_collection'],
        'targetDocId': m['target_doc_id'],
        'status': m['status'],
        'createdAt': m['created_at'],
        'reviewedAt': m['reviewed_at'],
        'reviewedBy': m['reviewed_by'],
        'rejectionReason': m['rejection_reason'],
      }, m['id'] as String);
    }).toList();
  }

  // -------------------- CRUD wrappers --------------------

  Future<void> saveDevice(Device d) => submitOrCommit(
        table: 'devices',
        actionType: 'add_device',
        title: 'تسجيل/تعديل جهاز',
        details: 'الجهاز: ${d.name} (${d.serialNumber})',
        payload: {'id': d.id, ...d.toMap()},
      );

  Future<void> deleteDevice(String id, String name) => submitOrCommit(
        table: 'devices',
        actionType: 'delete_device',
        title: 'حذف جهاز',
        details: 'حذف: $name',
        payload: {'id': id},
        targetDocId: id,
      );

  Future<void> saveCustodyCard(CustodyCard c) => submitOrCommit(
        table: 'custody_cards',
        actionType: 'add_custody',
        title: 'حفظ بطاقة عهدة',
        details: '${c.employeeName} (${c.cardNumber})',
        payload: {'id': c.id, ...c.toMap()},
      );

  Future<void> deleteCustodyCard(String id, String cardNumber) => submitOrCommit(
        table: 'custody_cards',
        actionType: 'delete_custody',
        title: 'حذف بطاقة عهدة',
        details: 'حذف: $cardNumber',
        payload: {'id': id},
        targetDocId: id,
      );

  Future<void> saveMovement(Movement m) => submitOrCommit(
        table: 'movements',
        actionType: 'add_movement',
        title: 'سند حركة',
        details: m.referenceNumber,
        payload: {'id': m.id, ...m.toMap()},
      );

  Future<void> saveTicket(MaintenanceTicket t) => submitOrCommit(
        table: 'maintenance_tickets',
        actionType: 'add_ticket',
        title: 'بلاغ صيانة',
        details: t.ticketNumber,
        payload: {'id': t.id, ...t.toMap()},
      );

  Future<void> deleteTicket(String id, String no) => submitOrCommit(
        table: 'maintenance_tickets',
        actionType: 'delete_ticket',
        title: 'حذف بلاغ',
        details: no,
        payload: {'id': id},
        targetDocId: id,
      );

  Future<void> savePhone(PhoneDirectoryEntry e) => submitOrCommit(
        table: 'phone_directory',
        actionType: 'add_phone',
        title: 'رقم هاتف',
        details: e.phoneNumber,
        payload: {'id': e.id, ...e.toMap()},
      );

  Future<void> deletePhone(String id, String name) => submitOrCommit(
        table: 'phone_directory',
        actionType: 'delete_phone',
        title: 'حذف رقم',
        details: name,
        payload: {'id': id},
        targetDocId: id,
      );

  Future<void> saveNetwork(TelecomNetworkInfo n) => submitOrCommit(
        table: 'telecom_networks',
        actionType: 'add_network',
        title: 'شبكة',
        details: n.name,
        payload: {'id': n.id, ...n.toMap()},
      );

  Future<void> deleteNetwork(String id, String name) => submitOrCommit(
        table: 'telecom_networks',
        actionType: 'delete_network',
        title: 'حذف شبكة',
        details: name,
        payload: {'id': id},
        targetDocId: id,
      );

  Future<void> approveRequest(PendingRequest req) async {
    if (!isSystemAdmin()) throw Exception('صلاحية مدير النظام فقط');
    final table = req.targetCollection;
    final id = req.targetDocId ?? req.payload['id'];
    if (req.actionType.startsWith('delete') && id != null) {
      await _client.from(table).delete().eq('id', id);
    } else {
      await _client.from(table).upsert(req.payload);
    }
    await _client.from('pending_requests').update({
      'status': 'approved',
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': userEmail,
    }).eq('id', req.id);
    await _logAudit(
      action: 'اعتماد: ${req.title}',
      entity: table,
      entityId: '$id',
      details: req.details,
    );
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    if (!isSystemAdmin()) throw Exception('صلاحية مدير النظام فقط');
    await _client.from('pending_requests').update({
      'status': 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': userEmail,
      'rejection_reason': reason,
    }).eq('id', requestId);
  }
}
