// Firestore REST API v1 client for Deno / Supabase Edge Functions.
// Uses Web Crypto (RS256) to sign a Google Service Account JWT and obtain an OAuth2 access token.

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

let cachedToken: { token: string; expiresAt: number } | null = null;

function getServiceAccount(): ServiceAccount {
  const raw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')?.trim();
  if (!raw) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT secret is not configured in Supabase.');
  }
  const jsonStr = raw.startsWith('{') ? raw : atob(raw);
  const parsed = JSON.parse(jsonStr) as ServiceAccount;
  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT JSON is missing required fields.');
  }
  return parsed;
}

function base64UrlEncode(data: Uint8Array | string): string {
  const bytes = typeof data === 'string' ? new TextEncoder().encode(data) : data;
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const clean = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s+/g, '');
  const binary = atob(clean);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

async function getAccessToken(): Promise<{ token: string; projectId: string }> {
  const sa = getServiceAccount();
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) {
    return { token: cachedToken.token, projectId: sa.project_id };
  }

  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = base64UrlEncode(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/datastore',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );

  const signingInput = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(sig))}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Google OAuth token exchange failed (${res.status}): ${errText}`);
  }
  const data = await res.json();
  cachedToken = {
    token: data.access_token,
    expiresAt: now + (Number(data.expires_in) || 3600),
  };
  return { token: cachedToken.token, projectId: sa.project_id };
}

export class VectorVal {
  constructor(public values: number[]) {}
}

// Convert JS value to Firestore REST Value
export function toFsValue(val: unknown): Record<string, unknown> {
  if (val === null || val === undefined) return { nullValue: null };
  if (val instanceof VectorVal) {
    return {
      mapValue: {
        fields: {
          __type__: { stringValue: '__vector__' },
          value: {
            arrayValue: {
              values: val.values.map((v) => ({ doubleValue: v })),
            },
          },
        },
      },
    };
  }
  if (val instanceof Date) {
    return { timestampValue: val.toISOString() };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    return Number.isInteger(val) ? { integerValue: String(val) } : { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map((item) => toFsValue(item)) } };
  }
  if (typeof val === 'object') {
    const fields: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(val as Record<string, unknown>)) {
      if (v !== undefined) {
        fields[k] = toFsValue(v);
      }
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

// Convert Firestore REST Value to JS value
export function fromFsValue(v: Record<string, unknown> | undefined): unknown {
  if (!v) return null;
  if ('nullValue' in v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return Number(v.doubleValue);
  if ('timestampValue' in v) return v.timestampValue;
  if ('arrayValue' in v) {
    const arr = (v.arrayValue as { values?: Record<string, unknown>[] })?.values ?? [];
    return arr.map((item) => fromFsValue(item));
  }
  if ('mapValue' in v) {
    const fields = (v.mapValue as { fields?: Record<string, Record<string, unknown>> })?.fields ?? {};
    if (fields.__type__?.stringValue === '__vector__') {
      const vecArr = (fields.value?.arrayValue as { values?: Record<string, unknown>[] })?.values ?? [];
      return vecArr.map((x) => Number(x.doubleValue ?? x.integerValue ?? 0));
    }
    const obj: Record<string, unknown> = {};
    for (const [k, fv] of Object.entries(fields)) {
      obj[k] = fromFsValue(fv);
    }
    return obj;
  }
  return null;
}

export function fromFsDoc(doc: { name?: string; fields?: Record<string, Record<string, unknown>> }): {
  id: string;
  data: Record<string, unknown>;
} {
  const parts = (doc.name ?? '').split('/');
  const id = parts[parts.length - 1] || '';
  const data: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(doc.fields ?? {})) {
    data[k] = fromFsValue(v);
  }
  return { id, data };
}

function toFsFields(obj: Record<string, unknown>): Record<string, unknown> {
  const fields: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined) {
      fields[k] = toFsValue(v);
    }
  }
  return fields;
}

async function baseUrl(): Promise<{ root: string; docPrefix: string; token: string }> {
  const { token, projectId } = await getAccessToken();
  const docPrefix = `projects/${projectId}/databases/(default)/documents`;
  return {
    root: `https://firestore.googleapis.com/v1/${docPrefix}`,
    docPrefix,
    token,
  };
}

export async function getDoc(path: string): Promise<{ id: string; exists: boolean; data: Record<string, unknown> }> {
  const { root, token } = await baseUrl();
  const res = await fetch(`${root}/${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (res.status === 404) {
    return { id: path.split('/').pop() || '', exists: false, data: {} };
  }
  if (!res.ok) {
    throw new Error(`Firestore getDoc(${path}) failed (${res.status}): ${await res.text()}`);
  }
  const json = await res.json();
  const parsed = fromFsDoc(json);
  return { id: parsed.id, exists: true, data: parsed.data };
}

export async function setDoc(
  path: string,
  data: Record<string, unknown>,
  merge = false,
): Promise<void> {
  const { root, token } = await baseUrl();
  const url = new URL(`${root}/${path}`);
  if (merge) {
    for (const key of Object.keys(data)) {
      url.searchParams.append('updateMask.fieldPaths', key);
    }
  }
  const res = await fetch(url.toString(), {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields: toFsFields(data) }),
  });
  if (!res.ok) {
    throw new Error(`Firestore setDoc(${path}) failed (${res.status}): ${await res.text()}`);
  }
}

export async function addDoc(
  collectionPath: string,
  data: Record<string, unknown>,
): Promise<string> {
  const { root, token } = await baseUrl();
  const res = await fetch(`${root}/${collectionPath}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields: toFsFields(data) }),
  });
  if (!res.ok) {
    throw new Error(`Firestore addDoc(${collectionPath}) failed (${res.status}): ${await res.text()}`);
  }
  const json = await res.json();
  const parts = (json.name as string).split('/');
  return parts[parts.length - 1];
}

export async function deleteDoc(path: string): Promise<void> {
  const { root, token } = await baseUrl();
  const res = await fetch(`${root}/${path}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok && res.status !== 404) {
    throw new Error(`Firestore deleteDoc(${path}) failed (${res.status}): ${await res.text()}`);
  }
}

export async function incrementFields(
  path: string,
  increments: Record<string, number>,
  extraFields: Record<string, unknown> = {},
): Promise<void> {
  const { root, docPrefix, token } = await baseUrl();
  const docName = `${docPrefix}/${path}`;
  const writes: unknown[] = [];

  if (Object.keys(extraFields).length > 0) {
    writes.push({
      update: {
        name: docName,
        fields: toFsFields(extraFields),
      },
      updateMask: { fieldPaths: Object.keys(extraFields) },
    });
  }

  const fieldTransforms = Object.entries(increments).map(([fieldPath, val]) => ({
    fieldPath,
    increment: Number.isInteger(val) ? { integerValue: String(val) } : { doubleValue: val },
  }));

  if (fieldTransforms.length > 0) {
    writes.push({
      transform: {
        document: docName,
        fieldTransforms,
      },
    });
  }

  const commitUrl = root.replace('/documents', '/documents:commit');
  const res = await fetch(commitUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ writes }),
  });
  if (!res.ok) {
    throw new Error(`Firestore commit(${path}) failed (${res.status}): ${await res.text()}`);
  }
}

export async function runStructuredQuery(
  structuredQuery: Record<string, unknown>,
  parentSubpath?: string,
): Promise<Array<{ id: string; data: Record<string, unknown> }>> {
  const { root, token } = await baseUrl();
  const target = parentSubpath ? `${root}/${parentSubpath}:runQuery` : `${root}:runQuery`;
  const res = await fetch(target, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ structuredQuery }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Firestore runQuery failed (${res.status}): ${err}`);
  }
  const rows = (await res.json()) as Array<{
    document?: { name?: string; fields?: Record<string, Record<string, unknown>> };
  }>;
  return rows.filter((r) => Boolean(r.document)).map((r) => fromFsDoc(r.document!));
}
