import * as fs from 'fs';
import * as path from 'path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  const rulesPath = path.resolve(__dirname, '../../firestore.rules');
  testEnv = await initializeTestEnvironment({
    projectId: 'exam-duty-9232f',
    firestore: {
      rules: fs.readFileSync(rulesPath, 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('DutyDesk Chatbot Firestore Security Rules', () => {
  it('denies client writes to chatbot_chunks, chatbot_stats_daily, chatbot_audit, and messages', async () => {
    const adminDb = testEnv.authenticatedContext('admin-uid', { admin: true }).firestore();
    const anonDb = testEnv.authenticatedContext('visitor-1').firestore();

    await assertFails(adminDb.collection('chatbot_chunks').doc('c1').set({ text: 'hack' }));
    await assertFails(adminDb.collection('chatbot_stats_daily').doc('2026-11-25').set({ messages: 99 }));
    await assertFails(adminDb.collection('chatbot_audit').doc('a1').set({ action: 'fake' }));
    await assertFails(
      anonDb.collection('chatbot_sessions').doc('s1').collection('messages').doc('m1').set({ text: 'hi' })
    );
  });

  it('prevents a visitor from reading another visitor session', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('chatbot_sessions').doc('sess-A').set({
        ownerUid: 'visitor-A',
        surface: 'landing',
      });
    });

    const visitorA = testEnv.authenticatedContext('visitor-A').firestore();
    const visitorB = testEnv.authenticatedContext('visitor-B').firestore();
    const auditor = testEnv.authenticatedContext('auditor-1', { auditor: true }).firestore();

    await assertSucceeds(visitorA.collection('chatbot_sessions').doc('sess-A').get());
    await assertFails(visitorB.collection('chatbot_sessions').doc('sess-A').get());
    await assertSucceeds(auditor.collection('chatbot_sessions').doc('sess-A').get());
  });

  it('restricts chatbot_settings and chatbot_documents writes to admin custom claim only', async () => {
    const adminDb = testEnv.authenticatedContext('admin-uid', { admin: true }).firestore();
    const visitorDb = testEnv.authenticatedContext('visitor-1').firestore();
    const auditorDb = testEnv.authenticatedContext('auditor-1', { auditor: true }).firestore();

    await assertSucceeds(adminDb.collection('chatbot_settings').doc('config').set({ botName: 'DutyDesk' }));
    await assertFails(visitorDb.collection('chatbot_settings').doc('config').set({ botName: 'Hacked' }));
    await assertFails(auditorDb.collection('chatbot_documents').doc('d1').set({ title: 'Test' }));
    await assertSucceeds(adminDb.collection('chatbot_documents').doc('d1').set({ title: 'Test' }));
  });

  it('denies unknown top-level collections by default', async () => {
    const anonDb = testEnv.authenticatedContext('visitor-1').firestore();
    await assertFails(anonDb.collection('secret_unknown_collection').doc('x').get());
  });
});
