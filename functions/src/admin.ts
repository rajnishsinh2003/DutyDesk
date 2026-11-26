import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Audience } from './types';

function assertAdmin(request: { auth?: { uid: string; token: Record<string, unknown> } }): string {
  if (!request.auth || request.auth.token?.admin !== true) {
    throw new HttpsError('permission-denied', 'Admin custom claim is required.');
  }
  return request.auth.uid;
}

/**
 * Allows visitors and invigilators to submit thumbs up/down feedback with optional comment.
 */
export const submitFeedback = onCall<{
  sessionId: string;
  messageId: string;
  value: 'up' | 'down';
  comment?: string;
}>(
  {
    region: 'asia-south1',
    enforceAppCheck: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required.');
    }

    const { sessionId, messageId, value, comment } = request.data || {};
    if (!sessionId || !messageId || (value !== 'up' && value !== 'down')) {
      throw new HttpsError('invalid-argument', 'Valid sessionId, messageId, and value (up|down) are required.');
    }

    const db = admin.firestore();
    const sessionRef = db.collection('chatbot_sessions').doc(sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists || sessionSnap.data()?.ownerUid !== request.auth.uid) {
      throw new HttpsError('permission-denied', 'You can only rate messages in your own session.');
    }

    const msgRef = sessionRef.collection('messages').doc(messageId);
    const msgSnap = await msgRef.get();
    if (!msgSnap.exists) {
      throw new HttpsError('not-found', 'Message not found.');
    }

    const prevValue = msgSnap.data()?.feedback?.value;
    await msgRef.update({
      feedback: {
        value,
        comment: (comment || '').trim().slice(0, 500),
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    });

    if (prevValue !== value) {
      const dateKey = new Date().toISOString().slice(0, 10);
      const statsRef = db.collection('chatbot_stats_daily').doc(dateKey);
      const updates: Record<string, admin.firestore.FieldValue> = {
        [value === 'up' ? 'thumbsUp' : 'thumbsDown']: admin.firestore.FieldValue.increment(1),
      };
      if (prevValue === 'up' || prevValue === 'down') {
        updates[prevValue === 'up' ? 'thumbsUp' : 'thumbsDown'] = admin.firestore.FieldValue.increment(-1);
      }
      await statsRef.set(updates, { merge: true });
    }

    return { success: true };
  }
);

/**
 * Admin-only callable to mark an assistant message as correct/incorrect and optionally
 * promote a corrected answer into an approved FAQ.
 */
export const adminReviewMessage = onCall<{
  sessionId: string;
  messageId: string;
  status: 'correct' | 'incorrect';
  correctedAnswer?: string;
  questionText?: string;
  saveAsFaq?: boolean;
  audience?: Audience[];
  language?: string;
}>(
  { region: 'asia-south1' },
  async (request) => {
    const adminUid = assertAdmin(request);
    const {
      sessionId,
      messageId,
      status,
      correctedAnswer,
      questionText,
      saveAsFaq,
      audience,
      language,
    } = request.data || {};

    if (!sessionId || !messageId || (status !== 'correct' && status !== 'incorrect')) {
      throw new HttpsError('invalid-argument', 'Valid sessionId, messageId, and review status required.');
    }

    const db = admin.firestore();
    const msgRef = db.collection('chatbot_sessions').doc(sessionId).collection('messages').doc(messageId);

    await msgRef.update({
      adminReview: {
        status,
        correctedAnswer: (correctedAnswer || '').trim(),
        reviewedBy: adminUid,
        reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    });

    let faqId: string | null = null;
    if (saveAsFaq && correctedAnswer && correctedAnswer.trim() && questionText && questionText.trim()) {
      const faqRef = await db.collection('chatbot_faqs').add({
        question: questionText.trim(),
        answer: correctedAnswer.trim(),
        audience: Array.isArray(audience) && audience.length > 0 ? audience : ['public', 'invigilator'],
        language: language || 'en',
        priority: 10,
        enabled: true,
        createdFrom: { sessionId, messageId },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      faqId = faqRef.id;
    }

    await db.collection('chatbot_audit').add({
      actorUid: adminUid,
      action: 'message_reviewed',
      targetId: `${sessionId}/${messageId}`,
      details: { status, saveAsFaq: !!saveAsFaq, faqId },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, faqId };
  }
);

/**
 * Admin-only callable to resolve an item in the Unanswered Queue (creates an FAQ or links a doc).
 */
export const resolveUnanswered = onCall<{
  unansweredId: string;
  answer?: string;
  linkedDocId?: string;
  audience?: Audience[];
  language?: string;
}>(
  { region: 'asia-south1' },
  async (request) => {
    const adminUid = assertAdmin(request);
    const { unansweredId, answer, linkedDocId, audience, language } = request.data || {};
    if (!unansweredId) {
      throw new HttpsError('invalid-argument', 'unansweredId is required.');
    }

    const db = admin.firestore();
    const itemRef = db.collection('chatbot_unanswered').doc(unansweredId);
    const snap = await itemRef.get();
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Unanswered item not found.');
    }

    const itemData = snap.data()!;
    let faqId: string | null = null;

    if (answer && answer.trim()) {
      const faqRef = await db.collection('chatbot_faqs').add({
        question: itemData.question || '',
        answer: answer.trim(),
        audience: Array.isArray(audience) && audience.length > 0 ? audience : ['public', 'invigilator'],
        language: language || itemData.locale || 'en',
        priority: 10,
        enabled: true,
        createdFrom: { unansweredId },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      faqId = faqRef.id;
    }

    await itemRef.update({
      status: 'resolved',
      resolvedBy: adminUid,
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      faqId,
      linkedDocId: linkedDocId || null,
    });

    await db.collection('chatbot_audit').add({
      actorUid: adminUid,
      action: 'unanswered_resolved',
      targetId: unansweredId,
      details: { faqId, linkedDocId: linkedDocId || null },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, faqId };
  }
);

/**
 * Admin-only callable to flag or unflag a conversation session.
 */
export const flagSession = onCall<{ sessionId: string; flagged: boolean }>(
  { region: 'asia-south1' },
  async (request) => {
    const adminUid = assertAdmin(request);
    const { sessionId, flagged } = request.data || {};
    if (!sessionId || typeof flagged !== 'boolean') {
      throw new HttpsError('invalid-argument', 'sessionId and flagged boolean are required.');
    }

    const db = admin.firestore();
    await db.collection('chatbot_sessions').doc(sessionId).update({ flagged });

    await db.collection('chatbot_audit').add({
      actorUid: adminUid,
      action: flagged ? 'session_flagged' : 'session_unflagged',
      targetId: sessionId,
      details: { flagged },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);

/**
 * Admin-only callable to record an audit log entry for client-side metadata/settings edits.
 */
export const logAdminAudit = onCall<{
  action: string;
  targetId?: string;
  details?: Record<string, unknown>;
}>(
  { region: 'asia-south1' },
  async (request) => {
    const adminUid = assertAdmin(request);
    const { action, targetId, details } = request.data || {};
    if (!action) {
      throw new HttpsError('invalid-argument', 'action is required.');
    }

    await admin.firestore().collection('chatbot_audit').add({
      actorUid: adminUid,
      action,
      targetId: targetId || null,
      details: details || {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);
