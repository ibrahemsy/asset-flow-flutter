// ============================================================
// نماذج البيانات - Asset Flow Flutter
// دائرة الاتصالات - وزارة الطوارئ وإدارة الكوارث
// ============================================================

enum UserRoleType {
  director,   // رئيس دائرة الاتصالات (صلاحيات الاعتماد والإدارة)
  technician, // فني اتصالات وشبكات
}

extension UserRoleTypeExt on UserRoleType {
  String get labelAr {
    switch (this) {
      case UserRoleType.director:
        return 'رئيس دائرة الاتصالات';
      case UserRoleType.technician:
        return 'فني اتصالات وشبكات';
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final UserRoleType role;
  final String department;
  final String? jobTitle;
  final String? phone;
  final String createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.department,
    this.jobTitle,
    this.phone,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] == 'director' ? UserRoleType.director : UserRoleType.technician,
      department: map['department'] ?? '',
      jobTitle: map['jobTitle'],
      phone: map['phone'],
      createdAt: map['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'role': role == UserRoleType.director ? 'director' : 'technician',
        'department': department,
        'jobTitle': jobTitle,
        'phone': phone,
        'createdAt': createdAt,
      };
}

enum RequestActionType {
  addDevice,
  editDevice,
  deleteDevice,
  addCustody,
  editCustody,
  deleteCustody,
  addMovement,
  addTicket,
  editTicket,
  addPhone,
  editPhone,
  addNetwork,
  joinDepartment,
}

class PendingRequest {
  final String id;
  final String actionType;
  final String title;
  final String details;
  final String requesterUid;
  final String requesterEmail;
  final String requesterName;
  final Map<String, dynamic> payload;
  final String targetCollection;
  final String? targetDocId;
  final String status; // pending | approved | rejected
  final String createdAt;
  final String? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  PendingRequest({
    required this.id,
    required this.actionType,
    required this.title,
    required this.details,
    required this.requesterUid,
    required this.requesterEmail,
    required this.requesterName,
    required this.payload,
    required this.targetCollection,
    this.targetDocId,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  factory PendingRequest.fromMap(Map<String, dynamic> map, String id) {
    return PendingRequest(
      id: id,
      actionType: map['actionType'] ?? '',
      title: map['title'] ?? '',
      details: map['details'] ?? '',
      requesterUid: map['requesterUid'] ?? '',
      requesterEmail: map['requesterEmail'] ?? '',
      requesterName: map['requesterName'] ?? '',
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      targetCollection: map['targetCollection'] ?? '',
      targetDocId: map['targetDocId'],
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? '',
      reviewedAt: map['reviewedAt'],
      reviewedBy: map['reviewedBy'],
      rejectionReason: map['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() => {
        'actionType': actionType,
        'title': title,
        'details': details,
        'requesterUid': requesterUid,
        'requesterEmail': requesterEmail,
        'requesterName': requesterName,
        'payload': payload,
        'targetCollection': targetCollection,
        'targetDocId': targetDocId,
        'status': status,
        'createdAt': createdAt,
        'reviewedAt': reviewedAt,
        'reviewedBy': reviewedBy,
        'rejectionReason': rejectionReason,
      };
}

// -------------------- بطاقة العهدة --------------------

class CustodyCardItem {
  final String id;
  final int no;
  final String name;
  final String description;
  final String unit;
  final int quantity;
  final String serialNumber;
  final String barcode;
  final String itemCode;
  final String receiptDetails;
  final String receiptDate;
  final String returnDetails;
  final String custodyNumber;
  final String returnDate;
  final int balance;
  final String notes;
  final String? deviceId;
  /// صور المادة (data URL base64 أو رابط)
  final List<String> imageUrls;

  CustodyCardItem({
    required this.id,
    required this.no,
    required this.name,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.serialNumber,
    required this.barcode,
    required this.itemCode,
    required this.receiptDetails,
    required this.receiptDate,
    required this.returnDetails,
    required this.custodyNumber,
    required this.returnDate,
    required this.balance,
    required this.notes,
    this.deviceId,
    this.imageUrls = const [],
  });

  factory CustodyCardItem.fromMap(Map<String, dynamic> map) {
    final images = (map['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return CustodyCardItem(
      id: map['id'] ?? '',
      no: map['no'] ?? 0,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      unit: map['unit'] ?? '',
      quantity: map['quantity'] ?? 0,
      serialNumber: map['serialNumber'] ?? '',
      barcode: map['barcode'] ?? '',
      itemCode: map['itemCode'] ?? '',
      receiptDetails: map['receiptDetails'] ?? '',
      receiptDate: map['receiptDate'] ?? '',
      returnDetails: map['returnDetails'] ?? '',
      custodyNumber: map['custodyNumber'] ?? '',
      returnDate: map['returnDate'] ?? '',
      balance: map['balance'] ?? 0,
      notes: map['notes'] ?? '',
      deviceId: map['deviceId'],
      imageUrls: images,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'no': no,
        'name': name,
        'description': description,
        'unit': unit,
        'quantity': quantity,
        'serialNumber': serialNumber,
        'barcode': barcode,
        'itemCode': itemCode,
        'receiptDetails': receiptDetails,
        'receiptDate': receiptDate,
        'returnDetails': returnDetails,
        'custodyNumber': custodyNumber,
        'returnDate': returnDate,
        'balance': balance,
        'notes': notes,
        'deviceId': deviceId,
        'imageUrls': imageUrls,
      };

  CustodyCardItem copyWith({List<String>? imageUrls, String? name, String? description}) {
    return CustodyCardItem(
      id: id,
      no: no,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit,
      quantity: quantity,
      serialNumber: serialNumber,
      barcode: barcode,
      itemCode: itemCode,
      receiptDetails: receiptDetails,
      receiptDate: receiptDate,
      returnDetails: returnDetails,
      custodyNumber: custodyNumber,
      returnDate: returnDate,
      balance: balance,
      notes: notes,
      deviceId: deviceId,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}

class CustodyCard {
  final String id;
  final String cardNumber;
  final String employeeName;
  /// الرقم الوطني / الهوية
  final String nationalId;
  final String jobTitle;
  final String directorate;
  final String workCenter;
  final String department;
  final String division;
  final String officeOrCenter;
  final String creationDate;
  final List<CustodyCardItem> items;
  final String employeeSignature;
  final String deliveryOfficerSignature;
  final String deptHeadSignature;
  final String warehouseKeeperSignature;
  final String adminEndorsement;
  final String endorsementDate;
  final String status; // active | archived | pending
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? createdBy;

  CustodyCard({
    required this.id,
    required this.cardNumber,
    required this.employeeName,
    this.nationalId = '',
    required this.jobTitle,
    required this.directorate,
    required this.workCenter,
    required this.department,
    required this.division,
    required this.officeOrCenter,
    required this.creationDate,
    required this.items,
    required this.employeeSignature,
    required this.deliveryOfficerSignature,
    required this.deptHeadSignature,
    required this.warehouseKeeperSignature,
    required this.adminEndorsement,
    required this.endorsementDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory CustodyCard.fromMap(Map<String, dynamic> map, String id) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((e) => CustodyCardItem.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    return CustodyCard(
      id: id,
      cardNumber: map['cardNumber'] ?? '',
      employeeName: map['employeeName'] ?? '',
      nationalId: map['nationalId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      directorate: map['directorate'] ?? '',
      workCenter: map['workCenter'] ?? '',
      department: map['department'] ?? '',
      division: map['division'] ?? '',
      officeOrCenter: map['officeOrCenter'] ?? '',
      creationDate: map['creationDate'] ?? '',
      items: itemsList,
      employeeSignature: map['employeeSignature'] ?? '',
      deliveryOfficerSignature: map['deliveryOfficerSignature'] ?? '',
      deptHeadSignature: map['deptHeadSignature'] ?? '',
      warehouseKeeperSignature: map['warehouseKeeperSignature'] ?? '',
      adminEndorsement: map['adminEndorsement'] ?? '',
      endorsementDate: map['endorsementDate'] ?? '',
      status: map['status'] ?? 'active',
      notes: map['notes'],
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toMap() => {
        'cardNumber': cardNumber,
        'employeeName': employeeName,
        'nationalId': nationalId,
        'jobTitle': jobTitle,
        'directorate': directorate,
        'workCenter': workCenter,
        'department': department,
        'division': division,
        'officeOrCenter': officeOrCenter,
        'creationDate': creationDate,
        'items': items.map((e) => e.toMap()).toList(),
        'employeeSignature': employeeSignature,
        'deliveryOfficerSignature': deliveryOfficerSignature,
        'deptHeadSignature': deptHeadSignature,
        'warehouseKeeperSignature': warehouseKeeperSignature,
        'adminEndorsement': adminEndorsement,
        'endorsementDate': endorsementDate,
        'status': status,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'createdBy': createdBy,
      };
}

// -------------------- الأجهزة --------------------

enum DeviceCategory {
  desktop,
  laptop,
  monitor,
  printer,
  scanner,
  ups,
  router,
  switchDevice,
  accessPoint,
  wirelessRadio,
  telephony,
  modem,
  cablesFiber,
  telecomGear,
  peripherals,
  spareParts,
  other,
}

extension DeviceCategoryExt on DeviceCategory {
  String get labelAr {
    switch (this) {
      case DeviceCategory.desktop:
        return 'حاسب مكتبي';
      case DeviceCategory.laptop:
        return 'حاسب محمول';
      case DeviceCategory.monitor:
        return 'شاشة عرض';
      case DeviceCategory.printer:
        return 'طابعة مكتبية';
      case DeviceCategory.scanner:
        return 'ماسح ضوئي';
      case DeviceCategory.ups:
        return 'مزود طاقة احتياطي';
      case DeviceCategory.router:
        return 'جهاز توجيه شبكي';
      case DeviceCategory.switchDevice:
        return 'محول شبكة مركزي';
      case DeviceCategory.accessPoint:
        return 'نقطة بث لاسلكي';
      case DeviceCategory.wirelessRadio:
        return 'اتصالات لاسلكية';
      case DeviceCategory.telephony:
        return 'هاتف أرضي أو شبكي';
      case DeviceCategory.modem:
        return 'مودم اتصالات';
      case DeviceCategory.cablesFiber:
        return 'كابلات ألياف ضوئية وشبكة';
      case DeviceCategory.telecomGear:
        return 'معدات شبكات واتصالات';
      case DeviceCategory.peripherals:
        return 'ملحقات حاسوب';
      case DeviceCategory.spareParts:
        return 'قطع غيار وأجزاء';
      case DeviceCategory.other:
        return 'تجهيزات أخرى';
    }
  }

  static DeviceCategory fromString(String value) {
    return DeviceCategory.values.firstWhere(
      (e) => e.name == value || e.name == value.replaceAll('_', ''),
      orElse: () => DeviceCategory.other,
    );
  }
}

enum DeviceCondition { excellent, good, needsMaintenance, defective, outOfService }

extension DeviceConditionExt on DeviceCondition {
  String get labelAr {
    switch (this) {
      case DeviceCondition.excellent:
        return 'ممتازة';
      case DeviceCondition.good:
        return 'جيدة';
      case DeviceCondition.needsMaintenance:
        return 'تحتاج صيانة';
      case DeviceCondition.defective:
        return 'معطلة';
      case DeviceCondition.outOfService:
        return 'خارج الخدمة';
    }
  }
}

enum DeviceStatus {
  inWarehouse,
  assignedEmployee,
  assignedDepartment,
  inMaintenance,
  decommissioned,
}

extension DeviceStatusExt on DeviceStatus {
  String get labelAr {
    switch (this) {
      case DeviceStatus.inWarehouse:
        return 'في المستودع';
      case DeviceStatus.assignedEmployee:
        return 'مسلّم لموظف';
      case DeviceStatus.assignedDepartment:
        return 'مسلّم لقسم';
      case DeviceStatus.inMaintenance:
        return 'قيد الصيانة';
      case DeviceStatus.decommissioned:
        return 'خارج الخدمة';
    }
  }
}

class DeviceAttachment {
  final String id;
  final String name;
  final String type; // image | pdf | doc
  final String dataUrl;
  final String uploadedAt;

  DeviceAttachment({
    required this.id,
    required this.name,
    required this.type,
    required this.dataUrl,
    required this.uploadedAt,
  });

  factory DeviceAttachment.fromMap(Map<String, dynamic> map) {
    return DeviceAttachment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'image',
      dataUrl: map['dataUrl'] ?? '',
      uploadedAt: map['uploadedAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'dataUrl': dataUrl,
        'uploadedAt': uploadedAt,
      };
}

class NetworkPortMapping {
  final String portNumber;
  final String pointNumber;
  final String officeLocation;
  final String? connectedDevice;
  final String? notes;

  NetworkPortMapping({
    required this.portNumber,
    required this.pointNumber,
    required this.officeLocation,
    this.connectedDevice,
    this.notes,
  });

  factory NetworkPortMapping.fromMap(Map<String, dynamic> map) {
    return NetworkPortMapping(
      portNumber: map['portNumber'] ?? '',
      pointNumber: map['pointNumber'] ?? '',
      officeLocation: map['officeLocation'] ?? '',
      connectedDevice: map['connectedDevice'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'portNumber': portNumber,
        'pointNumber': pointNumber,
        'officeLocation': officeLocation,
        'connectedDevice': connectedDevice,
        'notes': notes,
      };
}

class Device {
  final String id;
  final String name;
  final DeviceCategory category;
  final String manufacturer;
  final String model;
  final String serialNumber;
  final String barcode;
  final String assetNumber;
  final String? cpu;
  final String? ram;
  final String? storage;
  final String? caseType;
  final String? networkCables;
  final String? ipAddress;
  final String? macAddress;
  final int? portsCount;
  final List<NetworkPortMapping>? portMappings;
  final String purchaseDate;
  final String supplier;
  final DeviceCondition condition;
  final DeviceStatus status;
  final String location;
  final String? assignedEmployee;
  final String? assignedStationOrDept;
  final String? deliveryDate;
  final String? warrantyEnd;
  final bool? isVerified;
  final String? verifiedBy;
  final String? notes;
  final List<DeviceAttachment> attachments;
  final String createdAt;
  final String updatedAt;

  Device({
    required this.id,
    required this.name,
    required this.category,
    required this.manufacturer,
    required this.model,
    required this.serialNumber,
    required this.barcode,
    required this.assetNumber,
    this.cpu,
    this.ram,
    this.storage,
    this.caseType,
    this.networkCables,
    this.ipAddress,
    this.macAddress,
    this.portsCount,
    this.portMappings,
    required this.purchaseDate,
    required this.supplier,
    required this.condition,
    required this.status,
    required this.location,
    this.assignedEmployee,
    this.assignedStationOrDept,
    this.deliveryDate,
    this.warrantyEnd,
    this.isVerified,
    this.verifiedBy,
    this.notes,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Device.fromMap(Map<String, dynamic> map, String id) {
    final attachmentsList = (map['attachments'] as List<dynamic>?)
            ?.map((e) => DeviceAttachment.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final portsList = (map['portMappings'] as List<dynamic>?)
            ?.map((e) => NetworkPortMapping.fromMap(Map<String, dynamic>.from(e)))
            .toList();

    DeviceCategory cat = DeviceCategory.other;
    try {
      final catStr = (map['category'] as String? ?? 'other').replaceAll('_', '');
      cat = DeviceCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == catStr.toLowerCase() || e.name == map['category'],
        orElse: () => DeviceCategory.other,
      );
    } catch (_) {}

    DeviceCondition cond = DeviceCondition.good;
    try {
      final c = (map['condition'] as String? ?? 'good').replaceAll('_', '');
      cond = DeviceCondition.values.firstWhere(
        (e) => e.name.toLowerCase() == c.toLowerCase(),
        orElse: () => DeviceCondition.good,
      );
    } catch (_) {}

    DeviceStatus st = DeviceStatus.inWarehouse;
    try {
      final s = (map['status'] as String? ?? 'in_warehouse').replaceAll('_', '');
      st = DeviceStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == s.toLowerCase(),
        orElse: () => DeviceStatus.inWarehouse,
      );
    } catch (_) {}

    return Device(
      id: id,
      name: map['name'] ?? '',
      category: cat,
      manufacturer: map['manufacturer'] ?? '',
      model: map['model'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      barcode: map['barcode'] ?? '',
      assetNumber: map['assetNumber'] ?? '',
      cpu: map['cpu'],
      ram: map['ram'],
      storage: map['storage'],
      caseType: map['caseType'],
      networkCables: map['networkCables'],
      ipAddress: map['ipAddress'],
      macAddress: map['macAddress'],
      portsCount: map['portsCount'],
      portMappings: portsList,
      purchaseDate: map['purchaseDate'] ?? '',
      supplier: map['supplier'] ?? '',
      condition: cond,
      status: st,
      location: map['location'] ?? '',
      assignedEmployee: map['assignedEmployee'],
      assignedStationOrDept: map['assignedStationOrDept'],
      deliveryDate: map['deliveryDate'],
      warrantyEnd: map['warrantyEnd'],
      isVerified: map['isVerified'],
      verifiedBy: map['verifiedBy'],
      notes: map['notes'],
      attachments: attachmentsList,
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category.name,
        'manufacturer': manufacturer,
        'model': model,
        'serialNumber': serialNumber,
        'barcode': barcode,
        'assetNumber': assetNumber,
        'cpu': cpu,
        'ram': ram,
        'storage': storage,
        'caseType': caseType,
        'networkCables': networkCables,
        'ipAddress': ipAddress,
        'macAddress': macAddress,
        'portsCount': portsCount,
        'portMappings': portMappings?.map((e) => e.toMap()).toList(),
        'purchaseDate': purchaseDate,
        'supplier': supplier,
        'condition': condition.name,
        'status': status.name,
        'location': location,
        'assignedEmployee': assignedEmployee,
        'assignedStationOrDept': assignedStationOrDept,
        'deliveryDate': deliveryDate,
        'warrantyEnd': warrantyEnd,
        'isVerified': isVerified,
        'verifiedBy': verifiedBy,
        'notes': notes,
        'attachments': attachments.map((e) => e.toMap()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

// -------------------- الحركات --------------------

enum MovementType {
  handover,
  returnDevice,
  transferEmployee,
  transferDept,
  replacement,
  decommission,
  newIntake,
}

extension MovementTypeExt on MovementType {
  String get labelAr {
    switch (this) {
      case MovementType.handover:
        return 'تسليم جهاز لموظف';
      case MovementType.returnDevice:
        return 'إعادة جهاز إلى المستودع';
      case MovementType.transferEmployee:
        return 'نقل جهاز من موظف إلى آخر';
      case MovementType.transferDept:
        return 'نقل جهاز بين الأقسام';
      case MovementType.replacement:
        return 'استبدال جهاز';
      case MovementType.decommission:
        return 'إخراج جهاز من الخدمة';
      case MovementType.newIntake:
        return 'إدخال جهاز جديد إلى المستودع';
    }
  }
}

class Movement {
  final String id;
  final String referenceNumber;
  final MovementType type;
  final String deviceId;
  final String deviceName;
  final String serialNumber;
  final String? barcode;
  final String fromEntity;
  final String toEntity;
  final String executorName;
  final String date;
  final String reason;
  final String? notes;
  final String createdAt;

  Movement({
    required this.id,
    required this.referenceNumber,
    required this.type,
    required this.deviceId,
    required this.deviceName,
    required this.serialNumber,
    this.barcode,
    required this.fromEntity,
    required this.toEntity,
    required this.executorName,
    required this.date,
    required this.reason,
    this.notes,
    required this.createdAt,
  });

  factory Movement.fromMap(Map<String, dynamic> map, String id) {
    MovementType t = MovementType.handover;
    try {
      final s = (map['type'] as String? ?? 'handover').replaceAll('_', '');
      t = MovementType.values.firstWhere(
        (e) => e.name.toLowerCase().contains(s.toLowerCase()) || e.name == map['type'],
        orElse: () => MovementType.handover,
      );
    } catch (_) {}

    return Movement(
      id: id,
      referenceNumber: map['referenceNumber'] ?? '',
      type: t,
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      barcode: map['barcode'],
      fromEntity: map['fromEntity'] ?? '',
      toEntity: map['toEntity'] ?? '',
      executorName: map['executorName'] ?? '',
      date: map['date'] ?? '',
      reason: map['reason'] ?? '',
      notes: map['notes'],
      createdAt: map['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'referenceNumber': referenceNumber,
        'type': type.name,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'serialNumber': serialNumber,
        'barcode': barcode,
        'fromEntity': fromEntity,
        'toEntity': toEntity,
        'executorName': executorName,
        'date': date,
        'reason': reason,
        'notes': notes,
        'createdAt': createdAt,
      };
}

// -------------------- الصيانة --------------------

enum TicketPriority { critical, high, normal, low }

extension TicketPriorityExt on TicketPriority {
  String get labelAr {
    switch (this) {
      case TicketPriority.critical:
        return 'حرجة';
      case TicketPriority.high:
        return 'عالية';
      case TicketPriority.normal:
        return 'عادية';
      case TicketPriority.low:
        return 'منخفضة';
    }
  }
}

enum TicketStatus { newTicket, inProgress, waitingSpareParts, repaired, closed }

extension TicketStatusExt on TicketStatus {
  String get labelAr {
    switch (this) {
      case TicketStatus.newTicket:
        return 'جديد';
      case TicketStatus.inProgress:
        return 'قيد المعالجة';
      case TicketStatus.waitingSpareParts:
        return 'بانتظار قطع غيار';
      case TicketStatus.repaired:
        return 'تم الإصلاح';
      case TicketStatus.closed:
        return 'مغلق';
    }
  }
}

class MaintenanceTicket {
  final String id;
  final String ticketNumber;
  final String? deviceId;
  final String deviceName;
  final String? serialNumber;
  final String? barcode;
  final String faultDescription;
  final String stationOrDept;
  final String reportDate;
  final TicketPriority priority;
  final String assignedTech;
  final String actionsTaken;
  final String sparePartsUsed;
  final String? resolutionDate;
  final TicketStatus status;
  final String createdAt;

  MaintenanceTicket({
    required this.id,
    required this.ticketNumber,
    this.deviceId,
    required this.deviceName,
    this.serialNumber,
    this.barcode,
    required this.faultDescription,
    required this.stationOrDept,
    required this.reportDate,
    required this.priority,
    required this.assignedTech,
    required this.actionsTaken,
    required this.sparePartsUsed,
    this.resolutionDate,
    required this.status,
    required this.createdAt,
  });

  factory MaintenanceTicket.fromMap(Map<String, dynamic> map, String id) {
    TicketPriority p = TicketPriority.normal;
    try {
      p = TicketPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TicketPriority.normal,
      );
    } catch (_) {}

    TicketStatus s = TicketStatus.newTicket;
    try {
      final st = (map['status'] as String? ?? 'new').replaceAll('_', '');
      s = TicketStatus.values.firstWhere(
        (e) => e.name.toLowerCase().contains(st.toLowerCase()) || e.name == map['status'],
        orElse: () => TicketStatus.newTicket,
      );
    } catch (_) {}

    return MaintenanceTicket(
      id: id,
      ticketNumber: map['ticketNumber'] ?? '',
      deviceId: map['deviceId'],
      deviceName: map['deviceName'] ?? '',
      serialNumber: map['serialNumber'],
      barcode: map['barcode'],
      faultDescription: map['faultDescription'] ?? '',
      stationOrDept: map['stationOrDept'] ?? '',
      reportDate: map['reportDate'] ?? '',
      priority: p,
      assignedTech: map['assignedTech'] ?? '',
      actionsTaken: map['actionsTaken'] ?? '',
      sparePartsUsed: map['sparePartsUsed'] ?? '',
      resolutionDate: map['resolutionDate'],
      status: s,
      createdAt: map['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'ticketNumber': ticketNumber,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'serialNumber': serialNumber,
        'barcode': barcode,
        'faultDescription': faultDescription,
        'stationOrDept': stationOrDept,
        'reportDate': reportDate,
        'priority': priority.name,
        'assignedTech': assignedTech,
        'actionsTaken': actionsTaken,
        'sparePartsUsed': sparePartsUsed,
        'resolutionDate': resolutionDate,
        'status': status.name,
        'createdAt': createdAt,
      };
}

// -------------------- سجل التدقيق --------------------

class AuditLog {
  final String id;
  final String action;
  final String entity;
  final String entityId;
  final String userName;
  final String userEmail;
  final String timestamp;
  final String details;

  AuditLog({
    required this.id,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.userName,
    required this.userEmail,
    required this.timestamp,
    required this.details,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map, String id) {
    return AuditLog(
      id: id,
      action: map['action'] ?? '',
      entity: map['entity'] ?? '',
      entityId: map['entityId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      timestamp: map['timestamp'] ?? '',
      details: map['details'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'action': action,
        'entity': entity,
        'entityId': entityId,
        'userName': userName,
        'userEmail': userEmail,
        'timestamp': timestamp,
        'details': details,
      };
}

// -------------------- الاتصالات والشبكات --------------------

class TelecomNetworkInfo {
  final String id;
  final String name;
  final String type;
  final String? ipRange;
  final String? gateway;
  final String? bandwidth;
  final String? frequency;
  final String location;
  final String status; // active | inactive | degraded
  final String? notes;

  TelecomNetworkInfo({
    required this.id,
    required this.name,
    required this.type,
    this.ipRange,
    this.gateway,
    this.bandwidth,
    this.frequency,
    required this.location,
    required this.status,
    this.notes,
  });

  factory TelecomNetworkInfo.fromMap(Map<String, dynamic> map, String id) {
    return TelecomNetworkInfo(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      ipRange: map['ipRange'],
      gateway: map['gateway'],
      bandwidth: map['bandwidth'],
      frequency: map['frequency'],
      location: map['location'] ?? '',
      status: map['status'] ?? 'active',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'ipRange': ipRange,
        'gateway': gateway,
        'bandwidth': bandwidth,
        'frequency': frequency,
        'location': location,
        'status': status,
        'notes': notes,
      };
}

class PhoneDirectoryEntry {
  final String id;
  final String phoneNumber;
  final String employeeName;
  final String department;
  final String officeLocation;
  final String pbxPortNumber;
  final String? pointNumber;
  final String status; // active | inactive
  final String? notes;

  PhoneDirectoryEntry({
    required this.id,
    required this.phoneNumber,
    required this.employeeName,
    required this.department,
    required this.officeLocation,
    required this.pbxPortNumber,
    this.pointNumber,
    required this.status,
    this.notes,
  });

  factory PhoneDirectoryEntry.fromMap(Map<String, dynamic> map, String id) {
    return PhoneDirectoryEntry(
      id: id,
      phoneNumber: map['phoneNumber'] ?? '',
      employeeName: map['employeeName'] ?? '',
      department: map['department'] ?? '',
      officeLocation: map['officeLocation'] ?? '',
      pbxPortNumber: map['pbxPortNumber'] ?? '',
      pointNumber: map['pointNumber'],
      status: map['status'] ?? 'active',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'phoneNumber': phoneNumber,
        'employeeName': employeeName,
        'department': department,
        'officeLocation': officeLocation,
        'pbxPortNumber': pbxPortNumber,
        'pointNumber': pointNumber,
        'status': status,
        'notes': notes,
      };
}

class SystemSettings {
  final String headEmail;
  final String departmentName;
  final String? updatedAt;

  SystemSettings({
    required this.headEmail,
    required this.departmentName,
    this.updatedAt,
  });

  factory SystemSettings.fromMap(Map<String, dynamic> map) {
    return SystemSettings(
      headEmail: map['headEmail'] ?? '',
      departmentName: map['departmentName'] ?? '',
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() => {
        'headEmail': headEmail,
        'departmentName': departmentName,
        'updatedAt': updatedAt,
      };
}
