import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/spreadsheets',
    ],
  );

  static const String defaultHeadEmail = 'ferasnatof@gmail.com';
  static const String secondaryHeadEmail = 'gfa437926@gmail.com';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // -------------------- Auth --------------------

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// رمز وصول Google لـ Sheets API (مع إعادة طلب الصلاحية إن لزم)
  Future<String?> getGoogleAccessToken() async {
    GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) return null;
    // ضمان وجود صلاحية spreadsheets
    final granted = await _googleSignIn.requestScopes([
      'https://www.googleapis.com/auth/spreadsheets',
    ]);
    if (!granted) {
      // قد تكون ممنوحة مسبقاً على بعض المنصات
    }
    final auth = await account.authentication;
    return auth.accessToken;
  }

  // -------------------- Helpers --------------------

  static const Set<String> _allowedDepartmentCollections = {
    'devices',
    'custodyCards',
    'movements',
    'maintenanceTickets',
    'auditLogs',
    'phoneDirectory',
    'telecomNetworks',
  };

  CollectionReference _deptCollection(String name) {
    if (!_allowedDepartmentCollections.contains(name)) {
      throw ArgumentError.value(name, 'name', 'مجموعة بيانات غير مسموح بها');
    }
    return _db.collection('department_data').doc('telecom').collection(name);
  }

  bool isHeadOfDept(String? email, String headEmail) {
    if (email == null || email.isEmpty) return false;
    final normalized = email.trim().toLowerCase();
    return _adminEmails.contains(normalized);
  }

  /// مدير النظام (نفس رئيس الدائرة)
  bool isSystemAdmin(String? email, String headEmail) => isHeadOfDept(email, headEmail);

  // -------------------- System Settings --------------------

  List<String> _adminEmails = [];

  Future<SystemSettings> getSystemSettings() async {
    final doc = await _db.collection('system_settings').doc('telecom').get();
    if (!doc.exists || doc.data() == null) {
      throw StateError(
        'إعدادات النظام غير مهيأة. أنشئ system_settings/telecom من Firebase Console أولاً.',
      );
    }

    final data = doc.data()!;
    final rawEmails = data['adminEmails'];
    if (rawEmails is! List) {
      throw StateError('الحقل adminEmails مفقود أو ليس قائمة.');
    }
    _adminEmails = rawEmails
        .whereType<String>()
        .map((email) => email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet()
        .toList();

    return SystemSettings(
      headEmail: _adminEmails.isNotEmpty ? _adminEmails.first : '',
      departmentName: data['departmentName'] as String? ??
          'دائرة الاتصالات - وزارة الطوارئ وإدارة الكوارث',
      updatedAt: data['updatedAt']?.toString(),
    );
  }

  Future<void> updateHeadEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw ArgumentError.value(email, 'email', 'عنوان بريد غير صالح');
    }
    final admins = {..._adminEmails, normalized}.toList();
    await _db.collection('system_settings').doc('telecom').set({
      'adminEmails': admins,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    _adminEmails = admins;
  }

  // -------------------- Real-time Streams --------------------

  Stream<List<Device>> devicesStream() {
    return _deptCollection('devices').snapshots().map(
          (snap) => snap.docs.map((d) => Device.fromMap(d.data() as Map<String, dynamic>, d.id)).toList(),
        );
  }

  Stream<List<CustodyCard>> custodyCardsStream() {
    return _deptCollection('custodyCards').snapshots().map(
          (snap) => snap.docs.map((d) => CustodyCard.fromMap(d.data() as Map<String, dynamic>, d.id)).toList(),
        );
  }

  Stream<List<Movement>> movementsStream() {
    return _deptCollection('movements').snapshots().map(
          (snap) => snap.docs.map((d) => Movement.fromMap(d.data() as Map<String, dynamic>, d.id)).toList(),
        );
  }

  Stream<List<MaintenanceTicket>> ticketsStream() {
    return _deptCollection('maintenanceTickets').snapshots().map(
          (snap) => snap.docs.map((d) => MaintenanceTicket.fromMap(d.data() as Map<String, dynamic>, d.id)).toList(),
        );
  }

  Stream<List<AuditLog>> auditLogsStream() {
    return _deptCollection('auditLogs').snapshots().map(
          (snap) {
            final list = snap.docs.map((d) => AuditLog.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
            list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return list;
          },
        );
  }

  Stream<List<PhoneDirectoryEntry>> phoneDirectoryStream() {
    return _deptCollection('phoneDirectory').snapshots().map(
          (snap) => snap.docs.map((d) => PhoneDirectoryEntry.fromMap(d.data() as Map<String, dynamic>, d.id)).toList(),
        );
  }

  Stream<List<TelecomNetworkInfo>> telecomNetworksStream() {
    return _deptCollection('telecomNetworks').snapshots().map(
          (snap) => snap.docs.map((d) => TelecomNetworkInfo.fromMap(d.data() as Map<String, dynamic>, d.id)).toList(),
        );
  }

  Stream<List<PendingRequest>> pendingRequestsStream() {
    final user = currentUser;
    if (user == null) return const Stream<List<PendingRequest>>.empty();

    final Query<Map<String, dynamic>> query =
        isSystemAdmin(user.email, '') 
            ? _db.collection('pendingRequests')
            : _db.collection('pendingRequests')
                .where('requesterUid', isEqualTo: user.uid);

    return query.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => PendingRequest.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // -------------------- Write Operations --------------------

  Future<void> logAudit({
    required String action,
    required String entity,
    required String entityId,
    required String details,
    required User user,
  }) async {
    final id = 'log_${DateTime.now().millisecondsSinceEpoch}';
    final log = AuditLog(
      id: id,
      action: action,
      entity: entity,
      entityId: entityId,
      userName: user.displayName ?? 'المستخدم',
      userEmail: user.email ?? '',
      timestamp: DateTime.now().toIso8601String(),
      details: details,
    );
    await _deptCollection('auditLogs').doc(id).set(log.toMap());
  }

  Future<void> submitOrCommit({
    required String targetCollection,
    required String actionType,
    required String title,
    required String details,
    required Map<String, dynamic> payload,
    String? targetDocId,
    required User user,
    required bool isHead,
  }) async {
    if (isHead) {
      final ref = _deptCollection(targetCollection).doc(payload['id'] ?? targetDocId);
      if (actionType.startsWith('delete')) {
        await ref.delete();
      } else {
        await ref.set(payload, SetOptions(merge: true));
      }
      await logAudit(
        action: title,
        entity: targetCollection,
        entityId: payload['id'] ?? targetDocId ?? '',
        details: details,
        user: user,
      );
    } else {
      final reqId = 'req_${DateTime.now().millisecondsSinceEpoch}';
      final pending = PendingRequest(
        id: reqId,
        actionType: actionType,
        title: title,
        details: details,
        requesterUid: user.uid,
        requesterEmail: user.email ?? '',
        requesterName: user.displayName ?? 'موظف/فني الدائرة',
        payload: payload,
        targetCollection: targetCollection,
        targetDocId: payload['id'] ?? targetDocId,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );
      await _db.collection('pendingRequests').doc(reqId).set(pending.toMap());
    }
  }

  Future<void> approveRequest(PendingRequest req, User reviewer) async {
    final ref = _deptCollection(req.targetCollection).doc(req.targetDocId ?? req.payload['id']);
    if (req.actionType.startsWith('delete')) {
      await ref.delete();
    } else {
      await ref.set(req.payload, SetOptions(merge: true));
    }

    await _db.collection('pendingRequests').doc(req.id).update({
      'status': 'approved',
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewedBy': reviewer.email,
    });

    await logAudit(
      action: 'اعتماد طلب: ${req.title}',
      entity: req.targetCollection,
      entityId: req.targetDocId ?? '',
      details: req.details,
      user: reviewer,
    );
  }

  Future<void> rejectRequest(String requestId, String reason, User reviewer) async {
    await _db.collection('pendingRequests').doc(requestId).update({
      'status': 'rejected',
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewedBy': reviewer.email,
      'rejectionReason': reason,
    });
  }

  // Convenience wrappers
  Future<void> saveDevice(Device device, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'devices',
      actionType: 'add_device',
      title: 'تسجيل/تعديل جهاز',
      details: 'الجهاز: ${device.name} (${device.serialNumber})',
      payload: {'id': device.id, ...device.toMap()},
      user: user,
      isHead: isHead,
    );
  }

  Future<void> deleteDevice(String id, String name, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'devices',
      actionType: 'delete_device',
      title: 'حذف جهاز',
      details: 'حذف الجهاز: $name',
      payload: {'id': id},
      targetDocId: id,
      user: user,
      isHead: isHead,
    );
  }

  Future<void> saveCustodyCard(CustodyCard card, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'custodyCards',
      actionType: 'add_custody',
      title: 'حفظ بطاقة عهدة',
      details: 'الموظف: ${card.employeeName} (${card.cardNumber})',
      payload: {'id': card.id, ...card.toMap()},
      user: user,
      isHead: isHead,
    );
  }

  Future<void> deleteCustodyCard(String id, String cardNumber, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'custodyCards',
      actionType: 'delete_custody',
      title: 'حذف بطاقة عهدة',
      details: 'حذف بطاقة العهدة: $cardNumber',
      payload: {'id': id},
      targetDocId: id,
      user: user,
      isHead: isHead,
    );
  }

  Future<void> saveMovement(Movement movement, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'movements',
      actionType: 'add_movement',
      title: 'سند تسليم/إعادة',
      details: 'السند: ${movement.referenceNumber} (${movement.deviceName})',
      payload: {'id': movement.id, ...movement.toMap()},
      user: user,
      isHead: isHead,
    );
  }

  Future<void> saveTicket(MaintenanceTicket ticket, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'maintenanceTickets',
      actionType: 'add_ticket',
      title: 'بلاغ صيانة',
      details: 'البلاغ: ${ticket.ticketNumber} - ${ticket.deviceName}',
      payload: {'id': ticket.id, ...ticket.toMap()},
      user: user,
      isHead: isHead,
    );
  }

  Future<void> deleteTicket(String id, String ticketNumber, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'maintenanceTickets',
      actionType: 'delete_ticket',
      title: 'حذف بلاغ صيانة',
      details: 'حذف البلاغ: $ticketNumber',
      payload: {'id': id},
      targetDocId: id,
      user: user,
      isHead: isHead,
    );
  }

  Future<void> savePhoneEntry(PhoneDirectoryEntry entry, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'phoneDirectory',
      actionType: 'add_phone',
      title: 'إضافة/تعديل رقم هاتف',
      details: '${entry.employeeName} - ${entry.phoneNumber}',
      payload: {'id': entry.id, ...entry.toMap()},
      user: user,
      isHead: isHead,
    );
  }

  Future<void> deletePhoneEntry(String id, String name, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'phoneDirectory',
      actionType: 'delete_phone',
      title: 'حذف رقم هاتف',
      details: 'حذف: $name',
      payload: {'id': id},
      targetDocId: id,
      user: user,
      isHead: isHead,
    );
  }

  Future<void> saveTelecomNetwork(TelecomNetworkInfo network, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'telecomNetworks',
      actionType: 'add_network',
      title: 'إضافة/تعديل شبكة',
      details: network.name,
      payload: {'id': network.id, ...network.toMap()},
      user: user,
      isHead: isHead,
    );
  }

  Future<void> deleteTelecomNetwork(String id, String name, User user, bool isHead) async {
    await submitOrCommit(
      targetCollection: 'telecomNetworks',
      actionType: 'delete_network',
      title: 'حذف شبكة',
      details: 'حذف: $name',
      payload: {'id': id},
      targetDocId: id,
      user: user,
      isHead: isHead,
    );
  }
}
