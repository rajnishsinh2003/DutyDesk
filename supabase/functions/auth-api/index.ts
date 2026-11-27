// supabase/functions/auth-api/index.ts
// Server-side authentication Edge Function for DutyDesk
// Handles: invigilator login (PBKDF2), OTP request/verify, password reset
// for BOTH admins and invigilators.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

/* ─── Firebase Admin via REST ─── */
const FIREBASE_PROJECT_ID = "exam-duty-9232f";
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;

// Decode service account from env (Base64-encoded JSON)
function getServiceAccount(): Record<string, string> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "";
  try {
    return JSON.parse(atob(raw));
  } catch {
    return JSON.parse(raw);
  }
}

/* ─── JWT / OAuth helpers ─── */
async function createJwt(
  sa: Record<string, string>,
  scopes: string[]
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: scopes.join(" "),
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const enc = (o: unknown) =>
    btoa(JSON.stringify(o))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");
  const unsigned = `${enc(header)}.${enc(payload)}`;
  const keyData = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned)
  );
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
  return `${unsigned}.${sigB64}`;
}

let _cachedToken: { token: string; exp: number } | null = null;
async function getAccessToken(
  sa: Record<string, string>
): Promise<string> {
  if (_cachedToken && Date.now() / 1000 < _cachedToken.exp - 60) {
    return _cachedToken.token;
  }
  const jwt = await createJwt(sa, [
    "https://www.googleapis.com/auth/datastore",
    "https://www.googleapis.com/auth/firebase",
    "https://www.googleapis.com/auth/identitytoolkit",
  ]);
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const d = await r.json();
  if (!d.access_token) throw new Error("OAuth failed: " + JSON.stringify(d));
  _cachedToken = { token: d.access_token, exp: Date.now() / 1000 + (d.expires_in ?? 3600) };
  return d.access_token;
}

/* ─── Custom Token (Firebase Auth) ─── */
async function createCustomToken(
  sa: Record<string, string>,
  uid: string,
  claims: Record<string, unknown> = {}
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload: Record<string, unknown> = {
    iss: sa.client_email,
    sub: sa.client_email,
    aud: "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit",
    iat: now,
    exp: now + 3600,
    uid,
    claims,
  };
  const enc = (o: unknown) =>
    btoa(JSON.stringify(o))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");
  const unsigned = `${enc(header)}.${enc(payload)}`;
  const keyData = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned)
  );
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
  return `${unsigned}.${sigB64}`;
}

/* ─── PBKDF2 helpers ─── */
async function hashPassword(
  password: string,
  salt?: Uint8Array
): Promise<{ hash: string; salt: string }> {
  const s = salt ?? crypto.getRandomValues(new Uint8Array(16));
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    "PBKDF2",
    false,
    ["deriveBits"]
  );
  const bits = await crypto.subtle.deriveBits(
    { name: "PBKDF2", salt: s, iterations: 100000, hash: "SHA-256" },
    keyMaterial,
    256
  );
  return {
    hash: btoa(String.fromCharCode(...new Uint8Array(bits))),
    salt: btoa(String.fromCharCode(...s)),
  };
}

async function verifyPassword(
  password: string,
  storedHash: string,
  storedSalt: string
): Promise<boolean> {
  const saltBytes = Uint8Array.from(atob(storedSalt), (c) => c.charCodeAt(0));
  const { hash } = await hashPassword(password, saltBytes);
  return hash === storedHash;
}

/* ─── Firestore REST helpers ─── */
async function firestoreGet(
  token: string,
  path: string
): Promise<Record<string, unknown> | null> {
  const r = await fetch(`${FIRESTORE_BASE}/${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (r.status === 404) return null;
  if (!r.ok) throw new Error(`Firestore GET ${path}: ${r.status} ${await r.text()}`);
  return (await r.json()) as Record<string, unknown>;
}

async function firestoreQuery(
  token: string,
  collection: string,
  field: string,
  value: string
): Promise<Record<string, unknown>[]> {
  const r = await fetch(`${FIRESTORE_BASE}:runQuery`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: collection }],
        where: {
          fieldFilter: {
            field: { fieldPath: field },
            op: "EQUAL",
            value: { stringValue: value },
          },
        },
        limit: 2,
      },
    }),
  });
  if (!r.ok) throw new Error(`Firestore query: ${r.status}`);
  const results = (await r.json()) as Array<{ document?: Record<string, unknown> }>;
  return results.filter((r) => r.document).map((r) => r.document!);
}

async function firestorePatch(
  token: string,
  path: string,
  fields: Record<string, unknown>,
  fieldMask?: string[]
): Promise<void> {
  let url = `${FIRESTORE_BASE}/${path}`;
  if (fieldMask && fieldMask.length > 0) {
    url += "?" + fieldMask.map((f) => `updateMask.fieldPaths=${f}`).join("&");
  }
  const r = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });
  if (!r.ok) throw new Error(`Firestore PATCH ${path}: ${r.status} ${await r.text()}`);
}

async function firestoreDelete(
  token: string,
  path: string
): Promise<void> {
  await fetch(`${FIRESTORE_BASE}/${path}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${token}` },
  });
}

function fsString(v: string): Record<string, unknown> {
  return { stringValue: v };
}
function fsInt(v: number): Record<string, unknown> {
  return { integerValue: String(v) };
}
function fsBool(v: boolean): Record<string, unknown> {
  return { booleanValue: v };
}
function fsTimestamp(d: Date): Record<string, unknown> {
  return { timestampValue: d.toISOString() };
}
function readString(doc: Record<string, unknown>, field: string): string {
  const fields = doc.fields as Record<string, Record<string, unknown>> | undefined;
  if (!fields || !fields[field]) return "";
  return (fields[field].stringValue as string) ?? "";
}
function readInt(doc: Record<string, unknown>, field: string): number {
  const fields = doc.fields as Record<string, Record<string, unknown>> | undefined;
  if (!fields || !fields[field]) return 0;
  return parseInt((fields[field].integerValue as string) ?? "0", 10);
}
function readBool(doc: Record<string, unknown>, field: string): boolean {
  const fields = doc.fields as Record<string, Record<string, unknown>> | undefined;
  if (!fields || !fields[field]) return false;
  return (fields[field].booleanValue as boolean) ?? false;
}

/* ─── SHA-256 hex helper ─── */
async function sha256hex(input: string): Promise<string> {
  const buf = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(input)
  );
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/* ─── OTP generator ─── */
function generateOtp(): string {
  const arr = crypto.getRandomValues(new Uint8Array(4));
  const num = (arr[0] * 16777216 + arr[1] * 65536 + arr[2] * 256 + arr[3]) % 900000 + 100000;
  return String(num);
}

/* ─── Send email via Google Apps Script gateway ─── */
async function sendEmailViaGateway(
  token: string,
  to: string,
  subject: string,
  body: string
): Promise<boolean> {
  // Try to read gateway URL from settings/smtp
  let gatewayUrl = "https://script.google.com/macros/s/AKfycbyZmP20s6AepuCxF81hPVhjWPDeQBWn6jvT54LOL9r9LlA-xfWwjhmnABoCyoEQ9Xl2/exec";
  try {
    const smtpDoc = await firestoreGet(token, "settings/smtp");
    if (smtpDoc) {
      const url = readString(smtpDoc, "webGatewayUrl") || readString(smtpDoc, "gatewayUrl");
      if (url) gatewayUrl = url;
    }
  } catch { /* use default */ }

  const r = await fetch(gatewayUrl, {
    method: "POST",
    headers: { "Content-Type": "text/plain;charset=utf-8" },
    body: JSON.stringify({
      to,
      subject,
      body,
      fromName: "DutyDesk Examination System",
    }),
  });
  return r.ok || (r.status >= 200 && r.status < 400);
}

/* ─── Lookup & Update Firebase Auth user password by email ─── */
async function lookupFirebaseAuthUid(
  token: string,
  email: string
): Promise<string> {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/accounts:lookup`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email: [email] }),
    }
  );
  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Firebase Auth lookup failed (${res.status}): ${errText}`);
  }
  const data = await res.json();
  if (data.users && data.users.length > 0) {
    return data.users[0].localId as string;
  }
  return "";
}

async function updateFirebaseAuthPassword(
  token: string,
  email: string,
  newPassword: string
): Promise<void> {
  const uid = await lookupFirebaseAuthUid(token, email);
  if (!uid) {
    throw new Error(`No Firebase Auth user found for ${email}`);
  }

  const updateRes = await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/accounts:update`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        localId: uid,
        password: newPassword,
      }),
    }
  );
  if (!updateRes.ok) {
    const errText = await updateRes.text();
    throw new Error(`Firebase Auth password update failed (${updateRes.status}): ${errText}`);
  }
}

/* ═══════════════════════════════════════════════════════
   ROUTE: loginInvigilator
   ═══════════════════════════════════════════════════════ */
async function loginInvigilator(
  body: Record<string, string>,
  sa: Record<string, string>,
  token: string
): Promise<Response> {
  const { identifier, password } = body;
  if (!identifier || !password) {
    return json({ error: "identifier and password required" }, 400);
  }

  const clean = identifier.trim();
  const cleanPw = password.trim();

  // Search by mobile, then resourceId
  let docs = await firestoreQuery(token, "invigilators", "mobile", clean);
  if (docs.length === 0) {
    docs = await firestoreQuery(token, "invigilators", "resourceId", clean);
  }
  if (docs.length === 0) {
    // Try last 10 digits
    const digits = clean.replace(/\D/g, "");
    if (digits.length >= 10) {
      const last10 = digits.slice(-10);
      docs = await firestoreQuery(token, "invigilators", "mobile", last10);
    }
  }
  if (docs.length === 0) {
    return json({ error: "Invalid credentials" }, 401);
  }

  for (const doc of docs) {
    const docName = (doc.name as string) ?? "";
    const docId = docName.split("/").pop() ?? "";
    const storedHash = readString(doc, "passwordHash");
    const storedSalt = readString(doc, "passwordSalt");
    const plainPassword = readString(doc, "password");
    const resourceId = readString(doc, "resourceId");
    const name = readString(doc, "name") || "Invigilator";

    let matched = false;

    if (storedHash && storedSalt) {
      // Already PBKDF2 hashed
      matched = await verifyPassword(cleanPw, storedHash, storedSalt);
    } else {
      // Legacy: plain text password or resourceId
      if (plainPassword && plainPassword === cleanPw) {
        matched = true;
      } else if (resourceId && resourceId === cleanPw) {
        matched = true;
      }
    }

    if (matched) {
      // If still on legacy plain password, migrate to PBKDF2
      if (!storedHash && matched) {
        const { hash, salt } = await hashPassword(cleanPw);
        await firestorePatch(
          token,
          `invigilators/${docId}`,
          {
            passwordHash: fsString(hash),
            passwordSalt: fsString(salt),
          },
          ["passwordHash", "passwordSalt"]
        );
      }

      // Create Firebase Custom Token
      const customToken = await createCustomToken(sa, `inv_${docId}`, {
        role: "invigilator",
        invigilatorId: docId,
      });

      return json({
        customToken,
        userId: docId,
        userName: name,
        role: "invigilator",
      });
    }
  }

  return json({ error: "Invalid credentials" }, 401);
}

/* ═══════════════════════════════════════════════════════
   ROUTE: requestPasswordOtp
   Handles BOTH admin emails and invigilator identifiers
   ═══════════════════════════════════════════════════════ */
async function requestPasswordOtp(
  body: Record<string, string>,
  _sa: Record<string, string>,
  token: string
): Promise<Response> {
  const { identifier } = body;
  if (!identifier) return json({ error: "identifier required" }, 400);

  const clean = identifier.trim();
  const lower = clean.toLowerCase();

  let docId = "";
  let recipientEmail = "";
  let authEmail = "";
  let userName = "";
  let isAdmin = false;

  // Check if admin identifier
  const adminIdentifiers = [
    "admin", "admin@dutydesk.com", "admin@gmail.com",
    "examadmin", "rajnishsingh4641@gmail.com",
  ];
  
  if (adminIdentifiers.includes(lower) || lower.startsWith("admin")) {
    isAdmin = true;
    // Try to find the admin's email from settings
    let settingsEmail = "rajnishsingh4641@gmail.com";
    try {
      const credDoc = await firestoreGet(token, "settings/admin_credentials");
      if (credDoc) {
        settingsEmail = readString(credDoc, "email") || settingsEmail;
        userName = readString(credDoc, "name") || "Admin";
      } else {
        userName = "Admin";
      }
    } catch {
      userName = "Admin";
    }
    if (clean.includes("@")) {
      authEmail = lower;
      recipientEmail = lower === "admin@dutydesk.com" || lower === "admin@gmail.com"
        ? settingsEmail
        : lower;
    } else {
      authEmail = settingsEmail;
      recipientEmail = settingsEmail;
    }
    docId = `admin-${await sha256hex(authEmail)}`.substring(0, 24);
  } else {
    // Search invigilators
    let docs = await firestoreQuery(token, "invigilators", "mobile", clean);
    if (docs.length === 0) {
      docs = await firestoreQuery(token, "invigilators", "email", lower);
    }
    if (docs.length === 0) {
      docs = await firestoreQuery(token, "invigilators", "email", clean);
    }
    if (docs.length === 0) {
      docs = await firestoreQuery(token, "invigilators", "resourceId", clean);
    }
    if (docs.length === 0) {
      docs = await firestoreQuery(token, "invigilators", "resourceId", clean.toUpperCase());
    }
    // Try last 10 digits
    if (docs.length === 0) {
      const digits = clean.replace(/\D/g, "");
      if (digits.length >= 10) {
        docs = await firestoreQuery(token, "invigilators", "mobile", digits.slice(-10));
      }
    }
    if (docs.length === 0) {
      // Also check if it's an existing Firebase Auth admin email
      if (clean.includes("@")) {
        const uid = await lookupFirebaseAuthUid(token, lower).catch(() => "");
        if (!uid) {
          return json({ error: "No account found with this email address" }, 404);
        }
        isAdmin = true;
        authEmail = lower;
        recipientEmail = lower;
        userName = "Admin";
        docId = `admin-${await sha256hex(lower)}`.substring(0, 24);
      } else {
        return json({ error: "No user found with this identifier" }, 404);
      }
    } else {
      const doc = docs[0];
      const docName = (doc.name as string) ?? "";
      docId = docName.split("/").pop() ?? "";
      recipientEmail = readString(doc, "email");
      userName = readString(doc, "name") || "Invigilator";

      if (!recipientEmail || !recipientEmail.includes("@") || recipientEmail.endsWith("@dutydesk.local")) {
        return json({ error: "No registered email for this account. Contact your administrator." }, 400);
      }
    }
  }

  // Generate OTP and store hashed version
  const otp = generateOtp();
  const otpHash = await sha256hex(otp);

  await firestorePatch(
    token,
    `password_reset_otps/${docId}`,
    {
      otpHash: fsString(otpHash),
      email: fsString(recipientEmail),
      authEmail: fsString(authEmail || recipientEmail),
      userName: fsString(userName),
      isAdmin: fsBool(isAdmin),
      createdAt: fsTimestamp(new Date()),
      expiresAt: fsTimestamp(new Date(Date.now() + 10 * 60 * 1000)),
      verified: fsBool(false),
      attempts: fsInt(0),
    }
  );

  // Send OTP via email
  const emailSent = await sendEmailViaGateway(
    token,
    recipientEmail,
    "DutyDesk — Password Reset OTP",
    `Dear ${userName},\n\nYour one-time password (OTP) for resetting your DutyDesk credentials is:\n\n    ${otp}\n\nThis OTP is valid for 10 minutes. Do not share it with anyone.\n\nIf you did not request this, please ignore this email.\n\nRegards,\nDutyDesk Examination Management System`
  );

  if (!emailSent) {
    return json({ error: "Failed to send OTP email. Try again." }, 500);
  }

  // Mask email for client
  const parts = recipientEmail.split("@");
  const masked = parts[0].length <= 2
    ? `***@${parts[1]}`
    : `${parts[0][0]}${"*".repeat(parts[0].length - 2)}${parts[0][parts[0].length - 1]}@${parts[1]}`;

  return json({ maskedEmail: masked, docId });
}

/* ═══════════════════════════════════════════════════════
   ROUTE: verifyPasswordOtp
   ═══════════════════════════════════════════════════════ */
async function verifyPasswordOtp(
  body: Record<string, string>,
  _sa: Record<string, string>,
  token: string
): Promise<Response> {
  const { docId, otp } = body;
  if (!docId || !otp) return json({ error: "docId and otp required" }, 400);
  if (otp.length !== 6) return json({ error: "OTP must be 6 digits" }, 400);

  const doc = await firestoreGet(token, `password_reset_otps/${docId}`);
  if (!doc) return json({ error: "OTP expired or invalid. Request a new one." }, 400);

  const attempts = readInt(doc, "attempts");
  if (attempts >= 5) {
    return json({ error: "Too many incorrect attempts. Request a new OTP." }, 429);
  }

  const expiresAt = ((doc.fields as Record<string, Record<string, string>>)?.expiresAt?.timestampValue) ?? "";
  if (expiresAt && new Date(expiresAt) < new Date()) {
    return json({ error: "OTP has expired. Request a new one." }, 400);
  }

  // Increment attempts
  await firestorePatch(token, `password_reset_otps/${docId}`, {
    attempts: fsInt(attempts + 1),
  }, ["attempts"]);

  // Compare hashed OTP
  const enteredHash = await sha256hex(otp);
  const storedHash = readString(doc, "otpHash");

  if (enteredHash !== storedHash) {
    const remaining = 4 - attempts;
    return json({ error: `Incorrect OTP. ${remaining} attempt(s) remaining.` }, 401);
  }

  // Generate a one-time reset token
  const resetToken = await sha256hex(`${docId}-${Date.now()}-${otp}`);

  await firestorePatch(token, `password_reset_otps/${docId}`, {
    verified: fsBool(true),
    resetToken: fsString(resetToken),
  }, ["verified", "resetToken"]);

  return json({ resetToken });
}

/* ═══════════════════════════════════════════════════════
   ROUTE: resetPasswordWithToken
   Handles both admin and invigilator password resets
   ═══════════════════════════════════════════════════════ */
async function resetPasswordWithToken(
  body: Record<string, string>,
  _sa: Record<string, string>,
  token: string
): Promise<Response> {
  const { docId, resetToken, newPassword } = body;
  if (!docId || !resetToken || !newPassword) {
    return json({ error: "docId, resetToken and newPassword required" }, 400);
  }
  if (newPassword.length < 4) {
    return json({ error: "Password must be at least 4 characters" }, 400);
  }

  const otpDoc = await firestoreGet(token, `password_reset_otps/${docId}`);
  if (!otpDoc) return json({ error: "Reset session expired. Start over." }, 400);

  if (!readBool(otpDoc, "verified")) {
    return json({ error: "OTP not verified" }, 403);
  }

  const storedResetToken = readString(otpDoc, "resetToken");
  if (storedResetToken !== resetToken) {
    return json({ error: "Invalid reset token" }, 403);
  }

  const isAdmin = readBool(otpDoc, "isAdmin");
  const email = readString(otpDoc, "email");
  const authEmail = readString(otpDoc, "authEmail") || email;

  if (isAdmin) {
    if (newPassword.length < 6) {
      return json({ error: "Admin password must be at least 6 characters" }, 400);
    }

    // Update Firebase Auth password first so login works immediately
    await updateFirebaseAuthPassword(token, authEmail, newPassword);

    // Update admin password in Firestore (hashed)
    const { hash, salt } = await hashPassword(newPassword);
    await firestorePatch(
      token,
      "settings/admin_credentials",
      {
        passwordHash: fsString(hash),
        passwordSalt: fsString(salt),
        passwordUpdatedAt: fsTimestamp(new Date()),
        updatedBy: fsString(authEmail),
      },
      ["passwordHash", "passwordSalt", "passwordUpdatedAt", "updatedBy"]
    );
  } else {
    // Update invigilator password (hashed)
    const { hash, salt } = await hashPassword(newPassword);
    await firestorePatch(
      token,
      `invigilators/${docId}`,
      {
        passwordHash: fsString(hash),
        passwordSalt: fsString(salt),
        passwordUpdatedAt: fsTimestamp(new Date()),
      },
      ["passwordHash", "passwordSalt", "passwordUpdatedAt"]
    );
  }

  // Clean up OTP doc
  await firestoreDelete(token, `password_reset_otps/${docId}`);

  // Send confirmation email (best-effort)
  try {
    const userName = readString(otpDoc, "userName") || "User";
    await sendEmailViaGateway(
      token,
      email,
      "DutyDesk — Password Reset Successful",
      `Dear ${userName},\n\nYour DutyDesk login password has been successfully updated.\n\nIf you did not make this change, please contact your administrator immediately.\n\nRegards,\nDutyDesk Examination Management System`
    );
  } catch { /* best effort */ }

  return json({ success: true });
}

/* ─── JSON response helper ─── */
function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
    },
  });
}

/* ═══════════════════════════════════════════════════════
   MAIN HANDLER
   ═══════════════════════════════════════════════════════ */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return json({ ok: true });
  }

  try {
    const body = await req.json();
    const action = body.action as string;

    const sa = getServiceAccount();
    const token = await getAccessToken(sa);

    switch (action) {
      case "loginInvigilator":
        return await loginInvigilator(body, sa, token);
      case "requestPasswordOtp":
        return await requestPasswordOtp(body, sa, token);
      case "verifyPasswordOtp":
        return await verifyPasswordOtp(body, sa, token);
      case "resetPasswordWithToken":
        return await resetPasswordWithToken(body, sa, token);
      default:
        return json({ error: `Unknown action: ${action}` }, 400);
    }
  } catch (e) {
    console.error("auth-api error:", e);
    return json({ error: "Internal server error" }, 500);
  }
});
