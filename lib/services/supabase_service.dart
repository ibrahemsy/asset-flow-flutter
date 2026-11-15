import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// خدمة Supabase للمصادقة والبيانات وطلبات الاعتماد.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const Set<String> _allowedOperationalTables = {
    'devices', 'custody_cards', 'movements', 'maintenance_tickets',
    'phone_directory', 'telecom_networks', 'network_switches',
  };

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

  /// Current administrator nominates the next manager and selects the destination
  /// Supabase project. This creates a request only; it does not transfer data.
  Future<String> requestAdminHandover({
    required String proposedAdminEmail,
    required String targetProjectRef,
  }) async {
    const sourceProjectRef = 'cqqibuobtfgoxavskrjp';
    final email = proposedAdminEmail.trim().toLowerCase();
    final target = targetProjectRef.trim().toLowerCase();
    final emailParts = email.split('@');
    if (emailParts.length != 2 || emailParts.first.isEmpty || !emailParts.last.contains('.')) {
      throw ArgumentError('يرجى إدخال بريد المدير الجديد بصورة صحيحة');
    }
    if (target.length != 20 || !RegExp(r'^[a-z0-9]+$').hasMatch(target)) {
      throw ArgumentError('معرّف مشروع Supabase يجب أن يتكون من 20 حرفاً أو رقماً صغيراً');
    }
    if (target == sourceProjectRef) {
      throw ArgumentError('يجب أن يكون المشروع الجديد مختلفاً عن المشروع الحالي');
    }
    final result = await _client.rpc('request_admin_handover', params: {
      'p_proposed_admin_email': email,
      'p_source_project_ref': sourceProjectRef,
      'p_target_project_ref': target,
    });
    if (result == null || result.toString().isEmpty) {
      throw StateError('لم يتم إنشاء طلب التسليم');
    }
    return result.toString();
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
    values.remove('portMappings'); // Stored in network_switch_ports.
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
      'network_switches': ['switch_number','name','model','location','ports_count','status','notes'],
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
      'switch_number':'switchNumber', 'ports_count':'portsCount',
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
    if (!_allowedOperationalTables.contains(table)) {
      throw ArgumentError('جدول غير مسموح ضمن عمليات التطبيق: $table');
    }
    final admin = await isSystemAdmin();
    if (admin) {
      final id = payload['id'] ?? targetDocId;
      if (actionType.startsWith('delete') && id != null) {
        await _client.from(table).delete().eq('id', id);
      } else {
        if (table == 'network_switches') {
          await _saveNetworkSwitchAtomically(payload);
        } else {
          await _client.from(table).upsert(_encodeOperationalPayload(payload, table: table));
        }
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

  Future<List<Map<String, dynamic>>> fetchNetworkSwitches() async {
    final rows = await _client.from('network_switches').select().order('name');
    final ports = await _client.from('network_switch_ports').select().order('port_number');
    final portsBySwitch = <String, List<Map<String, dynamic>>>{};
    for (final raw in ports as List) {
      final port = Map<String, dynamic>.from(raw);
      final switchId = port['switch_id'] as String;
      (portsBySwitch[switchId] ??= <Map<String, dynamic>>[]).add({
        'id': port['id'], 'portNumber': '${port['port_number']}',
        'pointNumber': port['point_number'] ?? '', 'officeLocation': port['office_location'] ?? '',
        'deviceId': port['device_id'], 'connectedDevice': port['connected_device_label'] ?? '',
        'notes': port['notes'] ?? '',
      });
    }
    return (rows as List).map((value) {
      final row = Map<String, dynamic>.from(value);
      final data = row['data'] is Map ? Map<String, dynamic>.from(row['data'] as Map) : <String, dynamic>{};
      final id = row['id'] as String;
      data.remove('portMappings');
      return {...row, ...data, 'id': id, 'portMappings': portsBySwitch[id] ?? <Map<String, dynamic>>[]};
    }).toList();
  }

  Future<void> _saveNetworkSwitchAtomically(Map<String, dynamic> item) async {
    final encoded = _encodeOperationalPayload(item, table: 'network_switches');
    final rawMappings = item['portMappings'];
    final mappings = rawMappings is List ? rawMappings : const [];
    final rows = <Map<String, dynamic>>[];
    final seenPorts = <int>{};
    final seenDevices = <String>{};
    final maxPorts = int.tryParse('${item['portsCount'] ?? item['ports_count'] ?? ''}');
    if (maxPorts == null || maxPorts < 1) throw ArgumentError('عدد منافذ السويتش غير صالح');
    for (final raw in mappings) {
      if (raw is! Map) continue;
      final mapping = Map<String, dynamic>.from(raw);
      final portNumber = int.tryParse('${mapping['portNumber'] ?? ''}');
      final deviceId = mapping['deviceId']?.toString().trim();
      if (portNumber == null || portNumber < 1 || portNumber > maxPorts || !seenPorts.add(portNumber)) {
        throw ArgumentError('أرقام المنافذ يجب أن تكون صحيحة وغير مكررة وضمن عدد منافذ السويتش');
      }
      if (deviceId != null && deviceId.isNotEmpty && !seenDevices.add(deviceId)) {
        throw ArgumentError('لا يمكن ربط الجهاز نفسه بأكثر من منفذ');
      }
      rows.add({
        'id': mapping['id'] ?? 'swp_${item['id']}_$portNumber',
        'port_number': portNumber,
        'point_number': '${mapping['pointNumber'] ?? ''}'.trim(),
        'office_location': '${mapping['officeLocation'] ?? ''}'.trim(),
        'device_id': deviceId == null || deviceId.isEmpty ? null : deviceId,
        'connected_device_label': '${mapping['connectedDevice'] ?? ''}'.trim(),
        'notes': '${mapping['notes'] ?? ''}'.trim(),
      });
    }
    await _client.rpc('save_network_switch_with_ports', params: {
      'p_switch': encoded,
      'p_ports': rows,
    });
  }
  Future<void> saveNetworkSwitch(Map<String, dynamic> item) => submitOrCommit(
        table: 'network_switches',
        actionType: 'save_network_switch',
        title: 'حفظ سويتش شبكة',
        details: '${item['name'] ?? item['switchNumber'] ?? item['id']}',
        payload: item,
      );

  Future<void> deleteNetworkSwitch(String id, String name) => submitOrCommit(
        table: 'network_switches',
        actionType: 'delete_network_switch',
        title: 'حذف سويتش شبكة',
        details: name,
        payload: {'id': id},
        targetDocId: id,
      );

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
    if (!_allowedOperationalTables.contains(table)) {
      throw ArgumentError('جدول الطلب غير مسموح: $table');
    }
    final id = req.targetDocId ?? req.payload['id'];
    if (req.actionType.startsWith('delete') && id != null) {
      await _client.from(table).delete().eq('id', id);
    } else {
      if (table == 'network_switches') {
        await _saveNetworkSwitchAtomically(req.payload);
      } else {
        await _client.from(table).upsert(_encodeOperationalPayload(req.payload, table: table));
      }
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
).hasMatch(email)) {
      throw ArgumentError('يرجى إدخال بريد المدير الجديد بصورة صحيحة');
    }
    if (!RegExp(r'^[a-z0-9]{20}
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
    values.remove('portMappings'); // Stored in network_switch_ports.
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
      'network_switches': ['switch_number','name','model','location','ports_count','status','notes'],
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
      'switch_number':'switchNumber', 'ports_count':'portsCount',
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
    if (!_allowedOperationalTables.contains(table)) {
      throw ArgumentError('جدول غير مسموح ضمن عمليات التطبيق: $table');
    }
    final admin = await isSystemAdmin();
    if (admin) {
      final id = payload['id'] ?? targetDocId;
      if (actionType.startsWith('delete') && id != null) {
        await _client.from(table).delete().eq('id', id);
      } else {
        if (table == 'network_switches') {
          await _saveNetworkSwitchAtomically(payload);
        } else {
          await _client.from(table).upsert(_encodeOperationalPayload(payload, table: table));
        }
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

  Future<List<Map<String, dynamic>>> fetchNetworkSwitches() async {
    final rows = await _client.from('network_switches').select().order('name');
    final ports = await _client.from('network_switch_ports').select().order('port_number');
    final portsBySwitch = <String, List<Map<String, dynamic>>>{};
    for (final raw in ports as List) {
      final port = Map<String, dynamic>.from(raw);
      final switchId = port['switch_id'] as String;
      (portsBySwitch[switchId] ??= <Map<String, dynamic>>[]).add({
        'id': port['id'], 'portNumber': '${port['port_number']}',
        'pointNumber': port['point_number'] ?? '', 'officeLocation': port['office_location'] ?? '',
        'deviceId': port['device_id'], 'connectedDevice': port['connected_device_label'] ?? '',
        'notes': port['notes'] ?? '',
      });
    }
    return (rows as List).map((value) {
      final row = Map<String, dynamic>.from(value);
      final data = row['data'] is Map ? Map<String, dynamic>.from(row['data'] as Map) : <String, dynamic>{};
      final id = row['id'] as String;
      data.remove('portMappings');
      return {...row, ...data, 'id': id, 'portMappings': portsBySwitch[id] ?? <Map<String, dynamic>>[]};
    }).toList();
  }

  Future<void> _saveNetworkSwitchAtomically(Map<String, dynamic> item) async {
    final encoded = _encodeOperationalPayload(item, table: 'network_switches');
    final rawMappings = item['portMappings'];
    final mappings = rawMappings is List ? rawMappings : const [];
    final rows = <Map<String, dynamic>>[];
    final seenPorts = <int>{};
    final seenDevices = <String>{};
    final maxPorts = int.tryParse('${item['portsCount'] ?? item['ports_count'] ?? ''}');
    if (maxPorts == null || maxPorts < 1) throw ArgumentError('عدد منافذ السويتش غير صالح');
    for (final raw in mappings) {
      if (raw is! Map) continue;
      final mapping = Map<String, dynamic>.from(raw);
      final portNumber = int.tryParse('${mapping['portNumber'] ?? ''}');
      final deviceId = mapping['deviceId']?.toString().trim();
      if (portNumber == null || portNumber < 1 || portNumber > maxPorts || !seenPorts.add(portNumber)) {
        throw ArgumentError('أرقام المنافذ يجب أن تكون صحيحة وغير مكررة وضمن عدد منافذ السويتش');
      }
      if (deviceId != null && deviceId.isNotEmpty && !seenDevices.add(deviceId)) {
        throw ArgumentError('لا يمكن ربط الجهاز نفسه بأكثر من منفذ');
      }
      rows.add({
        'id': mapping['id'] ?? 'swp_${item['id']}_$portNumber',
        'port_number': portNumber,
        'point_number': '${mapping['pointNumber'] ?? ''}'.trim(),
        'office_location': '${mapping['officeLocation'] ?? ''}'.trim(),
        'device_id': deviceId == null || deviceId.isEmpty ? null : deviceId,
        'connected_device_label': '${mapping['connectedDevice'] ?? ''}'.trim(),
        'notes': '${mapping['notes'] ?? ''}'.trim(),
      });
    }
    await _client.rpc('save_network_switch_with_ports', params: {
      'p_switch': encoded,
      'p_ports': rows,
    });
  }
  Future<void> saveNetworkSwitch(Map<String, dynamic> item) => submitOrCommit(
        table: 'network_switches',
        actionType: 'save_network_switch',
        title: 'حفظ سويتش شبكة',
        details: '${item['name'] ?? item['switchNumber'] ?? item['id']}',
        payload: item,
      );

  Future<void> deleteNetworkSwitch(String id, String name) => submitOrCommit(
        table: 'network_switches',
        actionType: 'delete_network_switch',
        title: 'حذف سويتش شبكة',
        details: name,
        payload: {'id': id},
        targetDocId: id,
      );

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
    if (!_allowedOperationalTables.contains(table)) {
      throw ArgumentError('جدول الطلب غير مسموح: $table');
    }
    final id = req.targetDocId ?? req.payload['id'];
    if (req.actionType.startsWith('delete') && id != null) {
      await _client.from(table).delete().eq('id', id);
    } else {
      if (table == 'network_switches') {
        await _saveNetworkSwitchAtomically(req.payload);
      } else {
        await _client.from(table).upsert(_encodeOperationalPayload(req.payload, table: table));
      }
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
).hasMatch(target)) {
      throw ArgumentError('معرّف مشروع Supabase يجب أن يتكون من 20 حرفاً أو رقماً صغيراً');
    }
    if (target == sourceProjectRef) {
      throw ArgumentError('يجب أن يكون المشروع الجديد مختلفاً عن المشروع الحالي');
    }
    final result = await _client.rpc('request_admin_handover', params: {
      'p_proposed_admin_email': email,
      'p_source_project_ref': sourceProjectRef,
      'p_target_project_ref': target,
    });
    if (result == null || result.toString().isEmpty) {
      throw StateError('لم يتم إنشاء طلب التسليم');
    }
    return result.toString();
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
    values.remove('portMappings'); // Stored in network_switch_ports.
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
      'network_switches': ['switch_number','name','model','location','ports_count','status','notes'],
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
      'switch_number':'switchNumber', 'ports_count':'portsCount',
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
    if (!_allowedOperationalTables.contains(table)) {
      throw ArgumentError('جدول غير مسموح ضمن عمليات التطبيق: $table');
    }
    final admin = await isSystemAdmin();
    if (admin) {
      final id = payload['id'] ?? targetDocId;
      if (actionType.startsWith('delete') && id != null) {
        await _client.from(table).delete().eq('id', id);
      } else {
        if (table == 'network_switches') {
          await _saveNetworkSwitchAtomically(payload);
        } else {
          await _client.from(table).upsert(_encodeOperationalPayload(payload, table: table));
        }
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

  Future<List<Map<String, dynamic>>> fetchNetworkSwitches() async {
    final rows = await _client.from('network_switches').select().order('name');
    final ports = await _client.from('network_switch_ports').select().order('port_number');
    final portsBySwitch = <String, List<Map<String, dynamic>>>{};
    for (final raw in ports as List) {
      final port = Map<String, dynamic>.from(raw);
      final switchId = port['switch_id'] as String;
      (portsBySwitch[switchId] ??= <Map<String, dynamic>>[]).add({
        'id': port['id'], 'portNumber': '${port['port_number']}',
        'pointNumber': port['point_number'] ?? '', 'officeLocation': port['office_location'] ?? '',
        'deviceId': port['device_id'], 'connectedDevice': port['connected_device_label'] ?? '',
        'notes': port['notes'] ?? '',
      });
    }
    return (rows as List).map((value) {
      final row = Map<String, dynamic>.from(value);
      final data = row['data'] is Map ? Map<String, dynamic>.from(row['data'] as Map) : <String, dynamic>{};
      final id = row['id'] as String;
      data.remove('portMappings');
      return {...row, ...data, 'id': id, 'portMappings': portsBySwitch[id] ?? <Map<String, dynamic>>[]};
    }).toList();
  }

  Future<void> _saveNetworkSwitchAtomically(Map<String, dynamic> item) async {
    final encoded = _encodeOperationalPayload(item, table: 'network_switches');
    final rawMappings = item['portMappings'];
    final mappings = rawMappings is List ? rawMappings : const [];
    final rows = <Map<String, dynamic>>[];
    final seenPorts = <int>{};
    final seenDevices = <String>{};
    final maxPorts = int.tryParse('${item['portsCount'] ?? item['ports_count'] ?? ''}');
    if (maxPorts == null || maxPorts < 1) throw ArgumentError('عدد منافذ السويتش غير صالح');
    for (final raw in mappings) {
      if (raw is! Map) continue;
      final mapping = Map<String, dynamic>.from(raw);
      final portNumber = int.tryParse('${mapping['portNumber'] ?? ''}');
      final deviceId = mapping['deviceId']?.toString().trim();
      if (portNumber == null || portNumber < 1 || portNumber > maxPorts || !seenPorts.add(portNumber)) {
        throw ArgumentError('أرقام المنافذ يجب أن تكون صحيحة وغير مكررة وضمن عدد منافذ السويتش');
      }
      if (deviceId != null && deviceId.isNotEmpty && !seenDevices.add(deviceId)) {
        throw ArgumentError('لا يمكن ربط الجهاز نفسه بأكثر من منفذ');
      }
      rows.add({
        'id': mapping['id'] ?? 'swp_${item['id']}_$portNumber',
        'port_number': portNumber,
        'point_number': '${mapping['pointNumber'] ?? ''}'.trim(),
        'office_location': '${mapping['officeLocation'] ?? ''}'.trim(),
        'device_id': deviceId == null || deviceId.isEmpty ? null : deviceId,
        'connected_device_label': '${mapping['connectedDevice'] ?? ''}'.trim(),
        'notes': '${mapping['notes'] ?? ''}'.trim(),
      });
    }
    await _client.rpc('save_network_switch_with_ports', params: {
      'p_switch': encoded,
      'p_ports': rows,
    });
  }
  Future<void> saveNetworkSwitch(Map<String, dynamic> item) => submitOrCommit(
        table: 'network_switches',
        actionType: 'save_network_switch',
        title: 'حفظ سويتش شبكة',
        details: '${item['name'] ?? item['switchNumber'] ?? item['id']}',
        payload: item,
      );

  Future<void> deleteNetworkSwitch(String id, String name) => submitOrCommit(
        table: 'network_switches',
        actionType: 'delete_network_switch',
        title: 'حذف سويتش شبكة',
        details: name,
        payload: {'id': id},
        targetDocId: id,
      );

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
    if (!_allowedOperationalTables.contains(table)) {
      throw ArgumentError('جدول الطلب غير مسموح: $table');
    }
    final id = req.targetDocId ?? req.payload['id'];
    if (req.actionType.startsWith('delete') && id != null) {
      await _client.from(table).delete().eq('id', id);
    } else {
      if (table == 'network_switches') {
        await _saveNetworkSwitchAtomically(req.payload);
      } else {
        await _client.from(table).upsert(_encodeOperationalPayload(req.payload, table: table));
      }
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
