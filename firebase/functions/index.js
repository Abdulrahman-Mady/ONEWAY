const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const roles = new Set(["user", "moderator", "businessOwner", "admin"]);

function configuredInitialAdminEmail() {
  // Runtime configuration is deliberately used instead of a client-visible
  // constant. Set with: firebase functions:config:set
  // oneway.initial_admin_email="owner@example.com"
  return (functions.config().oneway?.initial_admin_email || "")
    .trim()
    .toLowerCase();
}

function isSuperAdmin(context) {
  return context.auth?.token?.superAdmin === true;
}

function isAdmin(context) {
  return context.auth?.token?.role === "admin" ||
         context.auth?.token?.role === "superAdmin";
}

async function writeAuditLog({ actorUid, action, targetUid, metadata = {} }) {
  await db.collection("auditLogs").add({
    actor_uid: actorUid,
    action,
    target_uid: targetUid,
    metadata,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function grantInitialSuperAdmin(user) {
  const configuredEmail = configuredInitialAdminEmail();
  const email = (user.email || "").trim().toLowerCase();
  if (!configuredEmail || email !== configuredEmail) return false;

  await admin.auth().setCustomUserClaims(user.uid, { superAdmin: true });
  await db.collection("users").doc(user.uid).set(
    {
      uid: user.uid,
      email: user.email || null,
      role: "superAdmin",
      updated_time: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await writeAuditLog({
    actorUid: user.uid,
    action: "initial_super_admin_granted",
    targetUid: user.uid,
    metadata: { source: "configured-email" },
  });
  return true;
}

// ============================================================================
// Designated-admin allowlist
// The owner designates admin emails in one Firestore document:
//   admin_config/allowed_admin_emails  ->  { emails: ["a@x.com", ...] }
// It is readable and writable only through the Admin SDK (Firestore rules
// default-deny it for clients). New registrations on a listed email become
// admin automatically; existing accounts can call claimDesignatedAdminRole.
// ============================================================================

const ALLOWLIST_DOC = "admin_config/allowed_admin_emails";

async function readAllowedAdminEmails() {
  const snap = await db.doc(ALLOWLIST_DOC).get();
  const emails = snap.exists ? snap.data().emails : null;
  if (!Array.isArray(emails)) return new Set();
  return new Set(
    emails.map((e) => String(e).trim().toLowerCase()).filter((e) => e.length > 0),
  );
}

async function grantAllowlistedAdmin(user) {
  const email = (user.email || "").trim().toLowerCase();
  if (!email) return false;
  const allowed = await readAllowedAdminEmails();
  if (!allowed.has(email)) return false;

  await admin.auth().setCustomUserClaims(user.uid, { superAdmin: false, role: "admin" });
  await db.collection("users").doc(user.uid).set(
    {
      uid: user.uid,
      email: user.email || null,
      role: "admin",
      updated_time: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await writeAuditLog({
    actorUid: user.uid,
    action: "allowlisted_admin_granted",
    targetUid: user.uid,
    metadata: { source: "admin-email-allowlist" },
  });
  return true;
}

// Runs for future registrations. Existing owner accounts can call
// bootstrapInitialSuperAdmin after the runtime configuration is deployed.
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  const becameSuperAdmin = await grantInitialSuperAdmin(user);
  if (!becameSuperAdmin) {
    await grantAllowlistedAdmin(user);
  }
});

// Any signed-in user may ask; the server grants only when their email is the
// configured initial admin or is on the owner-designated allowlist. Existing
// accounts use this after their email is added to the list.
exports.claimDesignatedAdminRole = functions.https.onCall(async (_data, context) => {
  if (!context.auth?.uid || !context.auth.token.email) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication is required.");
  }
  const user = await admin.auth().getUser(context.auth.uid);
  if (await grantInitialSuperAdmin(user)) {
    return { role: "superAdmin", refreshTokenRequired: true };
  }
  if (await grantAllowlistedAdmin(user)) {
    return { role: "admin", refreshTokenRequired: true };
  }
  throw new functions.https.HttpsError(
    "permission-denied",
    "This email is not designated as an administrator.",
  );
});

// Only the super admin manages the designated-admin email list.
exports.addAllowedAdminEmail = functions.https.onCall(async (data, context) => {
  if (!isSuperAdmin(context)) {
    throw new functions.https.HttpsError("permission-denied", "Super administrator role required.");
  }
  const email = typeof data.email === "string" ? data.email.trim().toLowerCase() : "";
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    throw new functions.https.HttpsError("invalid-argument", "A valid email address is required.");
  }
  await db.doc(ALLOWLIST_DOC).set(
    { emails: admin.firestore.FieldValue.arrayUnion(email) },
    { merge: true },
  );
  await writeAuditLog({
    actorUid: context.auth.uid,
    action: "admin_email_allowlisted",
    targetUid: context.auth.uid,
    metadata: { email },
  });
  return { email };
});

exports.removeAllowedAdminEmail = functions.https.onCall(async (data, context) => {
  if (!isSuperAdmin(context)) {
    throw new functions.https.HttpsError("permission-denied", "Super administrator role required.");
  }
  const email = typeof data.email === "string" ? data.email.trim().toLowerCase() : "";
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required.");
  }
  await db.doc(ALLOWLIST_DOC).set(
    { emails: admin.firestore.FieldValue.arrayRemove(email) },
    { merge: true },
  );
  await writeAuditLog({
    actorUid: context.auth.uid,
    action: "admin_email_removed_from_allowlist",
    targetUid: context.auth.uid,
    metadata: { email },
  });
  return { email };
});

exports.listAllowedAdminEmails = functions.https.onCall(async (_data, context) => {
  if (!isSuperAdmin(context)) {
    throw new functions.https.HttpsError("permission-denied", "Super administrator role required.");
  }
  return { emails: Array.from(await readAllowedAdminEmails()).sort() };
});

// Allows only the configured account to bootstrap its own claim. No arbitrary
// email or UID is accepted from the client.
exports.bootstrapInitialSuperAdmin = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth?.uid || !context.auth.token.email) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication is required.");
    }
    const configuredEmail = configuredInitialAdminEmail();
    if (!configuredEmail || context.auth.token.email.toLowerCase() !== configuredEmail) {
      throw new functions.https.HttpsError("permission-denied", "This account is not the configured initial administrator.");
    }
    const user = await admin.auth().getUser(context.auth.uid);
    const assigned = await grantInitialSuperAdmin(user);
    if (!assigned) {
      throw new functions.https.HttpsError("failed-precondition", "Initial administrator configuration is missing or does not match this account.");
    }
    return { role: "superAdmin", refreshTokenRequired: true };
  },
);

// Super admins can grant operational roles, but can never grant another
// super-admin from the client. Every change is logged server-side.
exports.setUserRole = functions.https.onCall(async (data, context) => {
  if (!isSuperAdmin(context)) {
    throw new functions.https.HttpsError("permission-denied", "Super administrator role required.");
  }
  const uid = typeof data.uid === "string" ? data.uid.trim() : "";
  const role = typeof data.role === "string" ? data.role.trim() : "";
  if (!uid || !roles.has(role)) {
    throw new functions.https.HttpsError("invalid-argument", "A valid UID and role are required.");
  }
  const target = await admin.auth().getUser(uid);
  await admin.auth().setCustomUserClaims(uid, {
    ...(target.customClaims || {}),
    // The callable never grants super-admin. Explicitly remove an old claim
    // when an operational role is assigned.
    superAdmin: false,
    role,
  });
  await db.collection("users").doc(uid).set(
    {
      uid,
      role,
      updated_time: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await writeAuditLog({
    actorUid: context.auth.uid,
    action: "role_changed",
    targetUid: uid,
    metadata: { role },
  });
  return { uid, role, refreshTokenRequired: true };
});

// Admin/moderator can approve business application
exports.approveBusinessApplication = functions.https.onCall(async (data, context) => {
  if (!isAdmin(context)) {
    throw new functions.https.HttpsError("permission-denied", "Administrator role required.");
  }
  const businessId = typeof data.businessId === "string" ? data.businessId.trim() : "";
  const adminNotes = typeof data.adminNotes === "string" ? data.adminNotes.trim() : "";
  if (!businessId) {
    throw new functions.https.HttpsError("invalid-argument", "Business ID is required.");
  }

  const businessRef = db.collection("businesses").doc(businessId);
  const businessDoc = await businessRef.get();
  if (!businessDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Business application not found.");
  }

  const businessData = businessDoc.data();
  const ownerUid = businessData.ownerId;

  // Update business status to active
  await businessRef.update({
    status: "active",
    approved_at: admin.firestore.FieldValue.serverTimestamp(),
    admin_notes: adminNotes,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Update user role to businessOwner
  await admin.auth().setCustomUserClaims(ownerUid, {
    role: "businessOwner",
  });
  await db.collection("users").doc(ownerUid).set(
    {
      uid: ownerUid,
      role: "businessOwner",
      business_application_id: businessId,
      business_application_status: "approved",
      updated_time: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // Notify owner
  await db.collection("notifications").add({
    userId: ownerUid,
    title: "تم قبول طلب تسجيلك!",
    body: `تم قبول طلب تسجيل "${businessData.business_name}" وأصبحت منشأتك موثقة على OneWay.`,
    type: "business_approved",
    business_id: businessId,
    is_read: false,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: context.auth.uid,
    action: "business_approved",
    targetUid: ownerUid,
    metadata: { businessId, businessName: businessData.business_name },
  });

  return { success: true, businessId, ownerUid };
});

// Admin/moderator can reject business application
exports.rejectBusinessApplication = functions.https.onCall(async (data, context) => {
  if (!isAdmin(context)) {
    throw new functions.https.HttpsError("permission-denied", "Administrator role required.");
  }
  const businessId = typeof data.businessId === "string" ? data.businessId.trim() : "";
  const rejectionReason = typeof data.rejectionReason === "string" ? data.rejectionReason.trim() : "";
  if (!businessId) {
    throw new functions.https.HttpsError("invalid-argument", "Business ID is required.");
  }
  if (!rejectionReason) {
    throw new functions.https.HttpsError("invalid-argument", "Rejection reason is required.");
  }

  const businessRef = db.collection("businesses").doc(businessId);
  const businessDoc = await businessRef.get();
  if (!businessDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Business application not found.");
  }

  const businessData = businessDoc.data();
  const ownerUid = businessData.ownerId;

  // Update business status to rejected
  await businessRef.update({
    status: "rejected",
    rejected_at: admin.firestore.FieldValue.serverTimestamp(),
    rejection_reason: rejectionReason,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Update user role back to user (if they were businessOwner)
  await admin.auth().setCustomUserClaims(ownerUid, {
    role: "user",
  });
  await db.collection("users").doc(ownerUid).set(
    {
      uid: ownerUid,
      role: "user",
      business_application_status: "rejected",
      updated_time: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // Notify owner
  await db.collection("notifications").add({
    userId: ownerUid,
    title: "تم رفض طلب التسجيل",
    body: `تم رفض طلب تسجيل "${businessData.business_name}". السبب: ${rejectionReason}`,
    type: "business_rejected",
    business_id: businessId,
    is_read: false,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: context.auth.uid,
    action: "business_rejected",
    targetUid: ownerUid,
    metadata: { businessId, businessName: businessData.business_name, rejectionReason },
  });

  return { success: true, businessId, ownerUid };
});

// Admin can suspend business
exports.suspendBusiness = functions.https.onCall(async (data, context) => {
  if (!isAdmin(context)) {
    throw new functions.https.HttpsError("permission-denied", "Administrator role required.");
  }
  const businessId = typeof data.businessId === "string" ? data.businessId.trim() : "";
  const suspensionReason = typeof data.suspensionReason === "string" ? data.suspensionReason.trim() : "";
  if (!businessId) {
    throw new functions.https.HttpsError("invalid-argument", "Business ID is required.");
  }

  const businessRef = db.collection("businesses").doc(businessId);
  const businessDoc = await businessRef.get();
  if (!businessDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Business not found.");
  }

  const businessData = businessDoc.data();
  const ownerUid = businessData.ownerId;

  // Update business status to suspended
  await businessRef.update({
    status: "suspended",
    suspended_at: admin.firestore.FieldValue.serverTimestamp(),
    suspension_reason: suspensionReason,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Notify owner
  await db.collection("notifications").add({
    userId: ownerUid,
    title: "تم تعليق الحساب",
    body: `تم تعليق منشأتك "${businessData.business_name}". السبب: ${suspensionReason}`,
    type: "business_suspended",
    business_id: businessId,
    is_read: false,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: context.auth.uid,
    action: "business_suspended",
    targetUid: ownerUid,
    metadata: { businessId, businessName: businessData.business_name, suspensionReason },
  });

  return { success: true, businessId, ownerUid };
});

// Admin can set user role (alias for setUserRole with admin check)
exports.setUserRoleByAdmin = functions.https.onCall(async (data, context) => {
  if (!isAdmin(context)) {
    throw new functions.https.HttpsError("permission-denied", "Administrator role required.");
  }
  const uid = typeof data.uid === "string" ? data.uid.trim() : "";
  const role = typeof data.role === "string" ? data.role.trim() : "";
  if (!uid || !roles.has(role)) {
    throw new functions.https.HttpsError("invalid-argument", "A valid UID and role are required.");
  }

  const target = await admin.auth().getUser(uid);
  await admin.auth().setCustomUserClaims(uid, {
    ...(target.customClaims || {}),
    superAdmin: false,
    role,
  });
  await db.collection("users").doc(uid).set(
    {
      uid,
      role,
      updated_time: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await writeAuditLog({
    actorUid: context.auth.uid,
    action: "role_changed_by_admin",
    targetUid: uid,
    metadata: { role },
  });
  return { uid, role, refreshTokenRequired: true };
});

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  // Retain only a minimal audit record. Product-data deletion and retention
  // policy must be approved before destructive cleanup is enabled.
  await writeAuditLog({
    actorUid: user.uid,
    action: "auth_user_deleted",
    targetUid: user.uid,
  });
});

// Trigger: When business status changes to active, update user role
exports.onBusinessStatusChange = functions.firestore
  .document("businesses/{businessId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== after.status && after.status === "active") {
      const ownerUid = after.ownerId;
      if (ownerUid) {
        // Update user role to businessOwner
        await admin.auth().setCustomUserClaims(ownerUid, {
          role: "businessOwner",
        });
        await db.collection("users").doc(ownerUid).set(
          {
            role: "businessOwner",
            business_application_status: "approved",
            updated_time: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    }
  });
