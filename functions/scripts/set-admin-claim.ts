/**
 * One-time CLI script to assign Firebase Auth Custom Claims (`admin: true` or `auditor: true`)
 * to existing DutyDesk administrator/auditor accounts.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
 *   npx ts-node scripts/set-admin-claim.ts --email admin@dutydesk.com --role admin
 *   npx ts-node scripts/set-admin-claim.ts --email auditor@dutydesk.com --role auditor
 */

import * as admin from 'firebase-admin';

admin.initializeApp({
  projectId: 'exam-duty-9232f',
});

async function main() {
  const args = process.argv.slice(2);
  const emailIdx = args.indexOf('--email');
  const uidIdx = args.indexOf('--uid');
  const roleIdx = args.indexOf('--role');

  const email = emailIdx !== -1 ? args[emailIdx + 1] : undefined;
  const uid = uidIdx !== -1 ? args[uidIdx + 1] : undefined;
  const role = roleIdx !== -1 ? args[roleIdx + 1] : 'admin';
  const pwIdx = args.indexOf('--password');
  const password = pwIdx !== -1 ? args[pwIdx + 1] : undefined;

  if (!email && !uid) {
    console.error('Error: Provide --email <userEmail> or --uid <userUid>');
    process.exit(1);
  }

  if (role !== 'admin' && role !== 'auditor' && role !== 'revoke') {
    console.error('Error: --role must be "admin", "auditor", or "revoke"');
    process.exit(1);
  }

  let user: admin.auth.UserRecord;
  try {
    user = email
      ? await admin.auth().getUserByEmail(email)
      : await admin.auth().getUser(uid!);
    if (password) {
      user = await admin.auth().updateUser(user.uid, { password });
      console.log(`Updated password for ${user.email || user.uid}`);
    }
  } catch (err: unknown) {
    const code = (err as { code?: string })?.code;
    if (code === 'auth/user-not-found' && email && password) {
      user = await admin.auth().createUser({ email, password });
      console.log(`Created new Firebase Auth user: ${email} (${user.uid})`);
    } else {
      throw err;
    }
  }

  const existingClaims = user.customClaims || {};
  let newClaims: Record<string, boolean | undefined> = { ...existingClaims };

  if (role === 'admin') {
    newClaims = { ...existingClaims, admin: true, auditor: false };
  } else if (role === 'auditor') {
    newClaims = { ...existingClaims, admin: false, auditor: true };
  } else {
    newClaims = { ...existingClaims, admin: false, auditor: false };
  }

  await admin.auth().setCustomUserClaims(user.uid, newClaims);
  console.log(`Successfully updated custom claims for ${user.email || user.uid}:`, newClaims);
  console.log('Note: The user must sign out and sign back in (or refresh ID token) for claims to take effect.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Failed to set custom claim:', err);
  process.exit(1);
});
