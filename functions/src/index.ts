import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall, type CallableRequest } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const auth = getAuth();
const settingsRef = db.collection("system_settings").doc("telecom");
const requests = db.collection("adminHandoverRequests");
const audit = db.collection("adminHandoverAudit");

function requireAuth(authContext: CallableRequest["auth"] | undefined) {
  if (!authContext) throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  return authContext;
}

async function requireCurrentAdmin(uid: string, email: string | undefined) {
  const snap = await settingsRef.get();
  if (!snap.exists) throw new HttpsError("failed-precondition", "إعدادات الإدارة غير مهيأة.");
  const data = snap.data() ?? {};
  if (typeof data.currentAdminUid === "string") {
    if (data.currentAdminUid !== uid) throw new HttpsError("permission-denied", "هذه العملية متاحة للمدير الحالي فقط.");
  } else {
    const admins = Array.isArray(data.adminEmails) ? data.adminEmails : [];
    const normalized = (email ?? "").trim().toLowerCase();
    if (!normalized || !admins.some((v: unknown) => typeof v === "string" && v.trim().toLowerCase() === normalized)) {
      throw new HttpsError("permission-denied", "هذه العملية متاحة للمدير الحالي فقط.");
    }
  }
  return snap;
}

function normalizeEmail(value: unknown): string {
  if (typeof value !== "string") throw new HttpsError("invalid-argument", "أدخل بريداً إلكترونياً صالحاً.");
  const email = value.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpsError("invalid-argument", "أدخل بريداً إلكترونياً صالحاً.");
  }
  return email;
}

export const createAdminHandover = onCall(async (request) => {
  const caller = requireAuth(request.auth);
  const callerEmail = typeof caller.token.email === "string" ? caller.token.email : undefined;
  await requireCurrentAdmin(caller.uid, callerEmail);
  const invitedEmail = normalizeEmail(request.data?.invitedEmail);
  if (invitedEmail === (callerEmail ?? "").toLowerCase()) {
    throw new HttpsError("invalid-argument", "لا يمكن تسليم الإدارة إلى البريد نفسه.");
  }

  const target = await auth.getUserByEmail(invitedEmail).catch(() => null);
  if (!target) throw new HttpsError("not-found", "يجب أن يكون للمدير الجديد حساب مسجل أولاً.");
  if (!target.emailVerified) throw new HttpsError("failed-precondition", "يجب توثيق بريد المدير الجديد أولاً.");

  const ref = requests.doc();
  await db.runTransaction(async (tx) => {
    const settings = await tx.get(settingsRef);
    if (!settings.exists) throw new HttpsError("failed-precondition", "إعدادات الإدارة غير مهيأة.");
    const data = settings.data()!;
    if (data.pendingHandoverId) {
      throw new HttpsError("failed-precondition", "توجد عملية تسليم أخرى قيد التنفيذ.");
    }
    if (data.currentAdminUid && data.currentAdminUid !== caller.uid) {
      throw new HttpsError("permission-denied", "لم تعد أنت المدير الحالي.");
    }
    tx.create(ref, {
      fromAdminUid: caller.uid,
      fromAdminEmail: callerEmail ?? "",
      invitedEmail,
      toAdminUid: null,
      status: "awaiting_new_admin_acceptance",
      requestedAt: FieldValue.serverTimestamp(),
      acceptedAt: null,
      approvedAt: null,
      completedAt: null
    });
    tx.update(settingsRef, { pendingHandoverId: ref.id });
  });
  await audit.add({
    operationId: ref.id, eventType: "handover_requested",
    actorUid: caller.uid, invitedEmail, timestamp: FieldValue.serverTimestamp()
  });
  return { operationId: ref.id, status: "awaiting_new_admin_acceptance" };
});

export const findMyAdminHandoverInvitation = onCall(async (request) => {
  const caller = requireAuth(request.auth);
  const email = normalizeEmail(caller.token.email);
  if (caller.token.email_verified !== true) {
    throw new HttpsError("failed-precondition", "يجب توثيق بريد الحساب أولاً.");
  }
  const snapshot = await requests
    .where("invitedEmail", "==", email)
    .limit(20)
    .get();
  const invitations = snapshot.docs.filter(
    (doc) => doc.get("status") === "awaiting_new_admin_acceptance"
  );
  if (invitations.length === 0) {
    throw new HttpsError("not-found", "لا توجد دعوة تسليم معلقة لهذا البريد.");
  }
  if (invitations.length > 1) {
    throw new HttpsError("failed-precondition", "توجد أكثر من دعوة؛ راجع مالك النظام.");
  }
  const doc = invitations[0];
  return {
    operationId: doc.id,
    fromAdminEmail: doc.get("fromAdminEmail") ?? "",
    invitedEmail: email,
    requestedAt: doc.get("requestedAt")?.toDate?.()?.toISOString?.() ?? null
  };
});

export const acceptAdminHandover = onCall(async (request) => {
  const caller = requireAuth(request.auth);
  const email = normalizeEmail(caller.token.email);
  if (caller.token.email_verified !== true) {
    throw new HttpsError("failed-precondition", "يجب توثيق بريد الحساب أولاً.");
  }
  const operationId = String(request.data?.operationId ?? "");
  if (!operationId) throw new HttpsError("invalid-argument", "معرّف طلب التسليم مطلوب.");
  const ref = requests.doc(operationId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "طلب التسليم غير موجود.");
    const data = snap.data()!;
    if (data.invitedEmail !== email) throw new HttpsError("permission-denied", "هذا الطلب غير موجه إلى حسابك.");
    if (data.status !== "awaiting_new_admin_acceptance") {
      throw new HttpsError("failed-precondition", "حالة طلب التسليم لا تسمح بالقبول.");
    }
    tx.update(ref, {
      toAdminUid: caller.uid, toAdminEmail: email,
      status: "awaiting_current_admin_approval",
      acceptedAt: FieldValue.serverTimestamp()
    });
  });
  await audit.add({
    operationId, eventType: "handover_accepted", actorUid: caller.uid,
    timestamp: FieldValue.serverTimestamp()
  });
  return { operationId, status: "awaiting_current_admin_approval" };
});

export const approveAdminHandover = onCall(async (request) => {
  const caller = requireAuth(request.auth);
  const callerEmail = typeof caller.token.email === "string" ? caller.token.email : undefined;
  await requireCurrentAdmin(caller.uid, callerEmail);

  const authTime = Number(caller.token.auth_time ?? 0);
  const nowSeconds = Math.floor(Date.now() / 1000);
  if (!authTime || nowSeconds - authTime > 600) {
    throw new HttpsError("failed-precondition", "أعد تسجيل المصادقة ثم أكد التسليم خلال عشر دقائق.");
  }

  const operationId = String(request.data?.operationId ?? "");
  if (!operationId) throw new HttpsError("invalid-argument", "معرّف طلب التسليم مطلوب.");
  const handoverRef = requests.doc(operationId);
  const handoverSnap = await handoverRef.get();
  if (!handoverSnap.exists) throw new HttpsError("not-found", "طلب التسليم غير موجود.");
  const handover = handoverSnap.data()!;
  if (handover.fromAdminUid !== caller.uid || handover.status !== "awaiting_current_admin_approval") {
    throw new HttpsError("failed-precondition", "الطلب غير مقبول أو لم يعد تابعاً للمدير الحالي.");
  }
  if (typeof handover.toAdminUid !== "string") {
    throw new HttpsError("failed-precondition", "لم يقبل المدير الجديد الدعوة.");
  }

  const nextUser = await auth.getUser(handover.toAdminUid);
  if (!nextUser.email || nextUser.email.toLowerCase() !== handover.invitedEmail || !nextUser.emailVerified) {
    throw new HttpsError("failed-precondition", "تعذر التحقق من حساب المدير الجديد وبريده الموثق.");
  }

  // Firestore ownership is switched atomically first. Custom claims are
  // supplementary UI/server metadata; Firestore rules use currentAdminUid.
  await db.runTransaction(async (tx) => {
    const [settingsSnap, currentRequest] = await Promise.all([
      tx.get(settingsRef), tx.get(handoverRef)
    ]);
    if (!settingsSnap.exists || !currentRequest.exists) {
      throw new HttpsError("not-found", "إعدادات الإدارة أو طلب التسليم غير موجود.");
    }
    const current = settingsSnap.data()!;
    const latest = currentRequest.data()!;
    if (current.currentAdminUid && current.currentAdminUid !== caller.uid) {
      throw new HttpsError("aborted", "تغير المدير الحالي أثناء تنفيذ العملية.");
    }
    if (latest.status !== "awaiting_current_admin_approval" ||
        latest.fromAdminUid !== caller.uid || latest.toAdminUid !== nextUser.uid) {
      throw new HttpsError("aborted", "تغيرت حالة طلب التسليم.");
    }
    if (current.pendingHandoverId !== operationId) {
      throw new HttpsError("aborted", "معرّف عملية التسليم لا يطابق العملية النشطة.");
    }
    tx.update(settingsRef, {
      pendingHandoverId: FieldValue.delete(),
      currentAdminUid: nextUser.uid,
      currentAdminEmail: nextUser.email!.toLowerCase(),
      adminEmails: [nextUser.email!.toLowerCase()],
      updatedAt: new Date().toISOString(),
      lastHandoverId: operationId
    });
    tx.update(handoverRef, {
      status: "completed",
      approvedAt: FieldValue.serverTimestamp(),
      completedAt: FieldValue.serverTimestamp()
    });
    tx.create(audit.doc(), {
      operationId, eventType: "handover_completed",
      fromAdminUid: caller.uid, toAdminUid: nextUser.uid,
      actorUid: caller.uid, timestamp: FieldValue.serverTimestamp()
    });
  });

  // Set the new administrator's supplementary role claim only after the
  // authoritative UID switch has committed successfully.
  await auth.setCustomUserClaims(nextUser.uid, {
    ...nextUser.customClaims, role: "system_admin", department: "telecom"
  });

  // Cleanup is best-effort: the authoritative Firestore UID has already moved,
  // so the former administrator is no longer authorized by the security rules.
  const oldUser = await auth.getUser(caller.uid).catch(() => null);
  if (oldUser) {
    const claims = { ...(oldUser.customClaims ?? {}) };
    delete claims.role;
    delete claims.department;
    await auth.setCustomUserClaims(oldUser.uid, claims);
  }
  return { operationId, status: "completed", newAdminUid: nextUser.uid };
});

export const cancelAdminHandover = onCall(async (request) => {
  const caller = requireAuth(request.auth);
  const callerEmail = typeof caller.token.email === "string" ? caller.token.email : undefined;
  await requireCurrentAdmin(caller.uid, callerEmail);
  const operationId = String(request.data?.operationId ?? "");
  if (!operationId) throw new HttpsError("invalid-argument", "معرّف طلب التسليم مطلوب.");
  const ref = requests.doc(operationId);
  await db.runTransaction(async (tx) => {
    const [settingsSnap, requestSnap] = await Promise.all([
      tx.get(settingsRef), tx.get(ref)
    ]);
    if (!settingsSnap.exists || !requestSnap.exists) {
      throw new HttpsError("not-found", "طلب التسليم غير موجود.");
    }
    const settings = settingsSnap.data()!;
    const handover = requestSnap.data()!;
    if (handover.fromAdminUid !== caller.uid ||
        !["awaiting_new_admin_acceptance", "awaiting_current_admin_approval"].includes(handover.status)) {
      throw new HttpsError("failed-precondition", "لا يمكن إلغاء هذا الطلب في حالته الحالية.");
    }
    if (settings.pendingHandoverId !== operationId) {
      throw new HttpsError("aborted", "الطلب لم يعد العملية النشطة.");
    }
    tx.update(ref, { status: "cancelled", cancelledAt: FieldValue.serverTimestamp() });
    tx.update(settingsRef, { pendingHandoverId: FieldValue.delete() });
    tx.create(audit.doc(), {
      operationId, eventType: "handover_cancelled",
      actorUid: caller.uid, timestamp: FieldValue.serverTimestamp()
    });
  });
  return { operationId, status: "cancelled" };
});

export const getAdminHandoverStatus = onCall(async (request) => {
  const caller = requireAuth(request.auth);
  const operationId = String(request.data?.operationId ?? "");
  if (!operationId) throw new HttpsError("invalid-argument", "معرّف طلب التسليم مطلوب.");
  const snap = await requests.doc(operationId).get();
  if (!snap.exists) throw new HttpsError("not-found", "طلب التسليم غير موجود.");
  const data = snap.data()!;
  if (data.fromAdminUid !== caller.uid && data.toAdminUid !== caller.uid) {
    throw new HttpsError("permission-denied", "لا يمكنك الاطلاع على هذا الطلب.");
  }
  return {
    operationId, status: data.status,
    invitedEmail: data.invitedEmail,
    requestedAt: data.requestedAt?.toDate?.()?.toISOString() ?? null,
    acceptedAt: data.acceptedAt?.toDate?.()?.toISOString() ?? null,
    completedAt: data.completedAt?.toDate?.()?.toISOString() ?? null
  };
});
