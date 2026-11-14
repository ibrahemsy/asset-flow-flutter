import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// خدمة Supabase للمصادقة والبيانات وطلبات الاعتماد.
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
    const url = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://cqqibuobtfgoxavskrjp.supabase.co',
    );
    const publishableKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_NReQPyV3Xd1RoR_RWfqVRg_opiQkOOA',
    );
    await Supabase.initialize(url: url, publishableKey: publishableKey);
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

  /// Authorization is resolved by Postgres from private.admin_assignments.
  /// Never trust a locally stored email allow-list for privileged access.
  Future<String?> currentAppRole() async {
    final role = await _client.rpc('current_app_role');
    return role is String && role.isNotEmpty ? role : null;
  }

  Future<bool> isSystemAdmin() async {
    final result = await _client.rpc('is_app_admin');
    return result == true;
  }

  // -------------------- Helpers --------------------

  Map<String, dynamic> _decodeOperationalRow(dynamic value) {
    final row = Map<String, dynamic>.from(value as Map);
    final data = row.remove('data');
    final decoded = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return {...row, ...decoded, 'id': row['id']};
  }

  Map<String, dynamic> _encodeOperationalPayload(
    Map<String, dynamic> payload, {
    required String table,
  }) {
    final values = Map<String, dynamic>.from(payload);
    final id = values.remove('id');
    if (id == null || id.toString().isEmpty) {
      throw ArgumentError('يجب تحديد معرّف السجل قبل الحفظ');
    }
    dynamic pick(String camel, [String? alternate]) =>
        values[camel] ?? (alternate == null ? null : values[alternate]);
    final row = <String, dynamic>{'id': id, 'data': values};
    final columns = <String, List<String>>{
      'devices': ['name','category','manufacturer','model','serial_number','barcode','asset_number','condition','status','location','assigned_employee','notes'],
      'custody_cards': ['card_number','employee_name','national_id','job_title','department','division','office_or_center','creation_date','items','status','notes'],
      'movements': ['reference_number','type','device_id','device_name','serial_number','from_entity','to_entity','executor_name','date','reason','notes'],
      'maintenance_tickets': ['ticket_number','device_name','serial_number','fault_description','station_or_dept','report_date','priority','assigned_tech','actions_taken','spare_parts_used','status'],
      'phone_directory': ['phone_number','employee_name','department','office_location','pbx_port_number','point_number','status','notes'],
      'telecom_networks': ['name','type','ip_range','gateway','bandwidth','frequency','location','status','notes'],
    };
    const aliases = <String, String>{
      'serial_number':'serialNumber', 'asset_number':'assetNumber',
      'assigned_employee':'assignedEmployee', 'card_number':'cardNumber',
      'employee_name':'employeeName', 'national_id':'nationalId',
      'job_title':'jobTitle', 'office_or_center':'officeOrCenter',
      'creation_date':'creationDate', 'reference_number':'referenceNumber',
      'device_id':'deviceId', 'device_name':'deviceName',
      'from_entity':'fromEntity', 'to_entity':'toEntity',
      'executor_name':'executorName', 'ticket_number':'ticketNumber',
      'fault_description':'faultDescription', 'station_or_dept':'stationOrDept',
      'report_date':'reportDate', 'assigned_tech':'assignedTech',
      'actions_taken':'actionsTaken', 'spare_parts_used':'sparePartsUsed',
      'phone_number':'phoneNumber', 'office_location':'officeLocation', 'ip_range':'ipRange',
      'pbx_port_number':'pbxPortNumber', 'point_number':'pointNumber',
    };
    for (final column in columns[table] ?? const <String>[]) {
      final value = pick(aliases[column] ?? column);
      if (value != null) row[column] = value;
    }
    return row;
  }

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
    final admin = await isSystemAdmin();
    if (admin) {
      final id = payload['id'] ?? targetDocId;
      if (actionType.startsWith('delete') && id != null) {
        await _client.from(table).delete().eq('id', id);
      } else {
        await _client.from(table).upsert(_encodeOperationalPayload(payload, table: table));
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
        .map((r) => Device.fromMap(_decodeOperationalRow(r), r['id'] as String))
        .toList();
  }

  Future<List<CustodyCard>> fetchCustodyCards() async {
    final rows = await _client.from('custody_cards').select();
    return (rows as List)
        .map((r) => CustodyCard.fromMap(_decodeOperationalRow(r), r['id'] as String))
        .toList();
  }

  Future<List<Movement>> fetchMovements() async {
    final rows = await _client.from('movements').select();
    return (rows as List)
        .map((r) => Movement.fromMap(_decodeOperationalRow(r), r['id'] as String))
        .toList();
  }

  Future<List<MaintenanceTicket>> fetchTickets() async {
    final rows = await _client.from('maintenance_tickets').select();
    return (rows as List)
        .map((r) => MaintenanceTicket.fromMap(_decodeOperationalRow(r), r['id'] as String))
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
            PhoneDirectoryEntry.fromMap(_decodeOperationalRow(r), r['id'] as String))
        .toList();
  }

  Future<List<TelecomNetworkInfo>> fetchNetworks() async {
    final rows = await _client.from('telecom_networks').select();
    return (rows as List)
        .map((r) =>
            TelecomNetworkInfo.fromMap(_decodeOperationalRow(r), r['id'] as String))
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
    if (!await isSystemAdmin()) throw Exception('صلاحية مدير النظام فقط');
    final table = req.targetCollection;
    final id = req.targetDocId ?? req.payload['id'];
    if (req.actionType.startsWith('delete') && id != null) {
      await _client.from(table).delete().eq('id', id);
    } else {
      await _client.from(table).upsert(_encodeOperationalPayload(req.payload, table: table));
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
    if (!await isSystemAdmin()) throw Exception('صلاحية مدير النظام فقط');
    await _client.from('pending_requests').update({
      'status': 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': userEmail,
      'rejection_reason': reason,
    }).eq('id', requestId);
  }
}
