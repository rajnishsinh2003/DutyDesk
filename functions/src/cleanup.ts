import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';

/**
 * Scheduled daily cleanup job that deletes chatbot sessions (and their messages)
 * older than `retentionDays` configured in `chatbot_settings/config` (default 90 days).
 */
export const retentionCleanup = onSchedule(
  {
    schedule: 'every 24 hours',
    region: 'asia-south1',
    timeoutSeconds: 300,
  },
  async () => {
    const db = admin.firestore();
    const settingsSnap = await db.collection('chatbot_settings').doc('config').get();
    const retentionDays = (settingsSnap.data()?.retentionDays as number) || 90;

    const cutoffDate = new Date(Date.now() - retentionDays * 24 * 60 * 60 * 1000);
    const cutoffTs = admin.firestore.Timestamp.fromDate(cutoffDate);

    let deletedSessions = 0;
    while (true) {
      const oldSessions = await db
        .collection('chatbot_sessions')
        .where('lastMessageAt', '<', cutoffTs)
        .limit(100)
        .get();

      if (oldSessions.empty) break;

      for (const sessionDoc of oldSessions.docs) {
        // Delete messages subcollection first
        while (true) {
          const msgs = await sessionDoc.ref.collection('messages').limit(300).get();
          if (msgs.empty) break;
          const batch = db.batch();
          for (const m of msgs.docs) {
            batch.delete(m.ref);
          }
          await batch.commit();
        }
        await sessionDoc.ref.delete();
        deletedSessions++;
      }
    }

    if (deletedSessions > 0) {
      await db.collection('chatbot_audit').add({
        actorUid: 'system_scheduler',
        action: 'retention_cleanup',
        targetId: 'chatbot_sessions',
        details: { deletedSessions, retentionDays },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);
