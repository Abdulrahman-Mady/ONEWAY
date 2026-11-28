const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
// Canonical 3-role model: user (مستخدم عادي), businessOwner (صاحب مكان), admin (أدمن)
const roles = new Set(["user", "businessOwner", "admin"]);

function readLegacyConfig(section, key) {
  try {
    return functions.config()?.[section]?.[key] || "";
  } catch (_) {
    return "";
  }
}

function configuredInitialAdminEmail() {
  return (
    process.env.INITIAL_ADMIN_EMAIL ||
    readLegacyConfig("oneway", "initial_admin_email") ||
    ""
  )
    .trim()
    .toLowerCase();
}

function isSuperAdmin(context) {
  return context.auth?.token?.superAdmin === true;
}

function isAdmin(context) {
  return (
    context.auth?.token?.superAdmin === true ||
    context.auth?.token?.role === "admin" ||
    context.auth?.token?.role === "superAdmin"
  );
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

// ============================================================================
// AI Assistant (Gemini 3.8 Flash via Interactions API)
// Real LLM-backed bilingual (Egyptian Arabic & English) answers, grounded in
// the verified places collection with multi-turn context, GPS distance,
// personalized mobility awareness, and rich structured actions.
// Set the key with:
//   firebase functions:config:set oneway.gemini_api_key="..."
// or environment variable GEMINI_API_KEY.
// If no key is configured the function returns { fallback: true } and the
// app uses its full local omni-capable engine seamlessly.
// ============================================================================

const ASSISTANT_ROUTES = new Set([
  "HomeDashboard",
  "ExploreMap",
  "SearchFilters",
  "SubmitAccessibilityReport",
  "FavoritesPage",
  "EmergencySOS",
  "EgyptGuide",
  "MyReports",
  "NotificationsPage",
  "SettingsPage",
  "UserProfile",
  "EditProfile",
  "HelpSupportPage",
  "SuggestPlace",
  "BusinessRegistration",
  "BusinessAdminDashboard",
  "PrivacyPolicy",
  "TermsOfUse",
  "AboutApp",
]);

const ASSISTANT_ACTIONS = new Set([
  "SOS",
  "navigate",
  "directions",
  "call_place",
  "call_hotline",
  "favorite_add",
  "favorite_remove",
  "open_place",
  "setting",
  "open_url",
  ...ASSISTANT_ROUTES,
]);

const ASSISTANT_SETTINGS = new Set([
  "font_scale",
  "high_contrast",
  "theme_mode",
  "language",
  "voice_feedback",
  "tts_rate",
  "conversation_mode",
  "notifications",
  "mobility_type",
]);

const OFFICIAL_HOTLINES = new Set(["123", "122", "180", "16736", "16439", "16528"]);

function haversineKm(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function configuredGeminiKey() {
  return (
    process.env.GEMINI_API_KEY ||
    readLegacyConfig("oneway", "gemini_api_key") ||
    ""
  ).trim();
}

function extractInteractionText(payload) {
  const steps = Array.isArray(payload?.steps) ? payload.steps : [];
  for (let i = steps.length - 1; i >= 0; i -= 1) {
    const step = steps[i];
    if (step?.type !== "model_output") continue;
    const parts = Array.isArray(step.content) ? step.content : [];
    const text = parts
      .filter((p) => p?.type === "text" && typeof p.text === "string")
      .map((p) => p.text)
      .join("")
      .trim();
    if (text) return text;
  }
  return "";
}

exports.assistantQuery = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication is required.");
  }
  if (context.auth.token?.firebase?.sign_in_provider === "anonymous") {
    return { fallback: true };
  }
  const query = typeof data.query === "string" ? data.query.trim() : "";
  if (!query || query.length > 500) {
    throw new functions.https.HttpsError("invalid-argument", "Query must be 1-500 characters.");
  }
  const apiKey = configuredGeminiKey();
  if (!apiKey) {
    return { fallback: true };
  }

  const locale = data.locale === "en" ? "en" : "ar";
  const mobilityType = typeof data.mobilityType === "string"
    ? data.mobilityType.trim().slice(0, 80)
    : "";
  const prevInteractionId = typeof data.previousInteractionId === "string"
    ? data.previousInteractionId.trim().slice(0, 120)
    : "";
  const userLoc = data.userLocation &&
      typeof data.userLocation.lat === "number" &&
      typeof data.userLocation.lng === "number"
    ? { lat: data.userLocation.lat, lng: data.userLocation.lng }
    : null;
  const recentHistory = Array.isArray(data.history)
    ? data.history
        .slice(-8)
        .filter((h) => h && typeof h.text === "string")
        .map((h) => ({
          role: h.role === "model" ? "assistant" : "user",
          text: h.text.trim().slice(0, 220),
        }))
    : [];

  // Ground the answer in Firestore places (server-side read).
  const snap = await db
    .collection("places")
    .where("verification_status", "==", "verified")
    .limit(60)
    .get();
  const places = snap.docs.map((d) => {
    const p = d.data();
    const loc = p.location;
    let distanceKm = null;
    if (userLoc && loc && typeof loc.latitude === "number" && typeof loc.longitude === "number") {
      distanceKm = Number(
        haversineKm(userLoc.lat, userLoc.lng, loc.latitude, loc.longitude).toFixed(1),
      );
    }
    return {
      id: d.id,
      name: p.name,
      category: p.category,
      city: p.city,
      governorate: p.governorate,
      rating: p.rating,
      phone: p.phone_number || "",
      hours: p.opening_hours || "",
      distanceKm,
      fieldVerified: Boolean(p.verification_evidence && String(p.verification_evidence).trim()),
      features: p.accessibility_features || {},
    };
  });

  const systemPrompt = [
    locale === "en"
      ? "You are ONEWAY's smart, empathetic voice assistant for wheelchair & mobility accessibility in Egypt. Reply clearly in concise, natural English."
      : "إنت المساعد الصوتي المصري الذكي بتاع تطبيق وان واي (ONEWAY) لذوي الإعاقة الحركية ومستخدمي الكراسي المتحركة وكبار السن في مصر. اتكلم دايماً باللهجة المصرية الطبيعية المحترمة والواضحة والودودة (زي: أهلاً بيك، لقيتلك، المكان ده فيه رامب وأسانسير، تحب أفتحلك الاتجاهات؟) وبجمل قصيرة وسهلة تتسمع بالصوت.",
    "Ground all place answers strictly in the provided places list — never invent places or fake accessibility claims. If a feature is missing/false or if fieldVerified is false, say so honestly in Egyptian Arabic (مثلاً: المكان ده مضاف ولسه مستني فحص ميداني من فريقنا).",
    "You can also help with Egypt disability rights (Law 10/2018, Integrated Services Card, Cairo Metro Line 3 & LRT, adapted vehicles) and official hotlines (123 Ambulance, 122 Police, 180 Fire, 16736 Disability Council, 16439 Ministry of Social Solidarity, 16528 Cabinet).",
    "Return valid JSON matching the schema with: reply, spokenReply (short TTS-friendly version without URLs), action (nullable), actionParams (object), placeIds (up to 4 IDs from the list), and followUpSuggestions (2-3 short natural follow-up prompts).",
    "Supported actions: SOS, navigate (actionParams.route from allowed routes + optional category), directions (first placeId), call_place (first placeId), call_hotline (actionParams.phoneNumber from 123/122/180/16736/16439/16528), favorite_add, favorite_remove, open_place, setting (actionParams.settingKey & settingValue), open_url (https://rdis.moss.gov.eg/ only).",
  ].join("\n");

  const contextLines = [
    `User language: ${locale}`,
    mobilityType ? `User mobility profile: ${mobilityType}` : "",
    userLoc ? `User GPS available (distances in km included per place).` : "User GPS unavailable.",
    recentHistory.length > 0 ? `Recent conversation:\n${JSON.stringify(recentHistory)}` : "",
    `Available places:\n${JSON.stringify(places)}`,
    `Current user request: ${query}`,
  ].filter(Boolean).join("\n\n");

  const requestBody = {
    model: "gemini-3.8-flash",
    system_instruction: systemPrompt,
    input: contextLines,
    generation_config: {
      max_output_tokens: 1024,
      thinking_level: "minimal",
    },
    response_format: {
      type: "text",
      mime_type: "application/json",
      schema: {
        type: "object",
        properties: {
          reply: { type: "string" },
          spokenReply: { type: "string" },
          action: { type: "string", nullable: true },
          actionParams: { type: "object" },
          placeIds: {
            type: "array",
            items: { type: "string" },
          },
          followUpSuggestions: {
            type: "array",
            items: { type: "string" },
          },
        },
        required: ["reply", "placeIds"],
      },
    },
  };
  if (prevInteractionId) {
    requestBody.previous_interaction_id = prevInteractionId;
  }

  let resp;
  try {
    resp = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/interactions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
          "Api-Revision": "2026-05-20",
        },
        body: JSON.stringify(requestBody),
      },
    );
  } catch (_netErr) {
    return { fallback: true };
  }

  if (!resp.ok) {
    await writeAuditLog({
      actorUid: context.auth.uid,
      action: "assistant_llm_error",
      targetUid: context.auth.uid,
      metadata: { status: resp.status },
    });
    return { fallback: true };
  }

  let payload = null;
  let parsed = null;
  try {
    payload = await resp.json();
    const text = extractInteractionText(payload);
    parsed = JSON.parse(text);
  } catch (_e) {
    return { fallback: true };
  }

  const rawAction = typeof parsed.action === "string" ? parsed.action.trim() : null;
  const action = rawAction && ASSISTANT_ACTIONS.has(rawAction) ? rawAction : null;
  const rawParams = parsed.actionParams && typeof parsed.actionParams === "object"
    ? parsed.actionParams
    : {};

  // Strictly sanitize actionParams so the model cannot produce unapproved targets.
  const actionParams = {};
  if (action === "navigate" && typeof rawParams.route === "string" && ASSISTANT_ROUTES.has(rawParams.route)) {
    actionParams.route = rawParams.route;
  }
  if (typeof rawParams.category === "string" && rawParams.category.trim()) {
    actionParams.category = rawParams.category.trim().slice(0, 60);
  }
  if (action === "call_hotline" && typeof rawParams.phoneNumber === "string" && OFFICIAL_HOTLINES.has(rawParams.phoneNumber.trim())) {
    actionParams.phoneNumber = rawParams.phoneNumber.trim();
    actionParams.autoExecute = Boolean(rawParams.autoExecute);
  }
  if (action === "setting" && typeof rawParams.settingKey === "string" && ASSISTANT_SETTINGS.has(rawParams.settingKey)) {
    actionParams.settingKey = rawParams.settingKey;
    actionParams.settingValue = rawParams.settingValue;
  }
  if (action === "open_url" && rawParams.url === "https://rdis.moss.gov.eg/") {
    actionParams.url = rawParams.url;
  }

  const knownIds = new Set(places.map((p) => p.id));
  const placeIds = Array.isArray(parsed.placeIds)
    ? parsed.placeIds.filter((id) => knownIds.has(id)).slice(0, 4)
    : [];

  const followUpSuggestions = Array.isArray(parsed.followUpSuggestions)
    ? parsed.followUpSuggestions
        .filter((s) => typeof s === "string" && s.trim().length > 0)
        .map((s) => s.trim().slice(0, 80))
        .slice(0, 4)
    : [];

  const fallbackReply = locale === "en"
    ? "Sorry, I could not respond right now. Please try again."
    : "معلش، مش قادر أرد دلوقتي. جرب تاني.";

  const reply = typeof parsed.reply === "string" && parsed.reply.trim()
    ? parsed.reply.trim()
    : fallbackReply;

  const spokenReply = typeof parsed.spokenReply === "string" && parsed.spokenReply.trim()
    ? parsed.spokenReply.trim()
    : reply;

  return {
    fallback: false,
    reply,
    spokenReply,
    action,
    actionParams,
    placeIds,
    followUpSuggestions,
    interactionId: typeof payload?.id === "string" ? payload.id : null,
  };
});

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const cols = ["favorites", "notifications", "emergencyContacts"];
  for (const col of cols) {
    const snap = await db.collection(col).where("userId", "==", uid).get();
    if (!snap.empty) {
      const batch = db.batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }
  }
  await db.collection("users").doc(uid).delete().catch(() => {});
  await writeAuditLog({
    actorUid: uid,
    action: "auth_user_deleted_and_purged",
    targetUid: uid,
  });
});

// Atomic account & personal data deletion callable (avoids partial client scrub on requires-recent-login)
exports.deleteMyAccount = functions.https.onCall(async (_data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication is required.");
  }
  const uid = context.auth.uid;
  const cols = ["favorites", "notifications", "emergencyContacts"];
  for (const col of cols) {
    const snap = await db.collection(col).where("userId", "==", uid).get();
    if (!snap.empty) {
      const batch = db.batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }
  }
  await db.collection("users").doc(uid).delete().catch(() => {});
  await admin.auth().deleteUser(uid);
  await writeAuditLog({
    actorUid: uid,
    action: "self_account_deleted",
    targetUid: uid,
  });
  return { success: true };
});

// Automatically aggregate community review ratings onto places/{placeId}
exports.onReviewWritten = functions.firestore
  .document("reviews/{reviewId}")
  .onWrite(async (change) => {
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;
    const placeId = (after?.place_id || before?.place_id || "").trim();
    if (!placeId) return null;

    const snap = await db
      .collection("reviews")
      .where("place_id", "==", placeId)
      .where("status", "==", "published")
      .get();

    let count = 0;
    let total = 0;
    snap.docs.forEach((d) => {
      const r = Number(d.data()?.rating);
      if (!Number.isNaN(r) && r >= 1 && r <= 5) {
        total += r;
        count += 1;
      }
    });
    const avg = count > 0 ? Number((total / count).toFixed(2)) : 0;
    await db.collection("places").doc(placeId).update({
      rating: avg,
      review_count: count,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }).catch(() => {});
    return null;
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

// Trigger: Send a real FCM push notification (works even when app is closed)
// whenever a new notification document is created for a user.
exports.onNotificationCreated = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userId = typeof data?.userId === "string" ? data.userId.trim() : "";
    if (!userId) return null;

    const userSnap = await db.collection("users").doc(userId).get();
    if (!userSnap.exists) return null;

    const rawTokens = userSnap.data()?.fcm_tokens;
    const tokens = Array.isArray(rawTokens)
      ? rawTokens.filter((t) => typeof t === "string" && t.trim().length > 0)
      : [];
    if (tokens.length === 0) return null;

    const title = typeof data.title === "string" && data.title.trim()
      ? data.title.trim()
      : "ONEWAY";
    const body = typeof data.body === "string" ? data.body.trim() : "";

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: {
        notificationId: context.params.notificationId,
        type: typeof data.type === "string" ? data.type : "general",
        route: "/notifications",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "oneway_alerts",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    // Automatically prune stale / unregistered device tokens
    const invalidTokens = [];
    response.responses.forEach((res, idx) => {
      if (!res.success) {
        const code = res.error?.code || "";
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidTokens.push(tokens[idx]);
        }
      }
    });
    if (invalidTokens.length > 0) {
      await db.collection("users").doc(userId).update({
        fcm_tokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
    }
    return null;
  });
