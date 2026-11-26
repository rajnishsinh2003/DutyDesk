import * as admin from 'firebase-admin';

export interface RateLimitResult {
  allowed: boolean;
  reason?: 'rate_limit_minute' | 'rate_limit_day' | 'session_cap' | 'token_budget';
  retryAfterSeconds?: number;
}

/**
 * Pure helper to evaluate sliding-window counters (useful for unit testing).
 */
export function evaluateRateCounters(params: {
  minuteCount: number;
  dayCount: number;
  sessionCount: number;
  dailyTokensUsed: number;
  maxPerMinute?: number;
  maxPerDay?: number;
  perSessionCap: number;
  dailyTokenBudget: number;
}): RateLimitResult {
  const maxPerMinute = params.maxPerMinute ?? 10;
  const maxPerDay = params.maxPerDay ?? 100;

  if (params.dailyTokenBudget > 0 && params.dailyTokensUsed >= params.dailyTokenBudget) {
    return { allowed: false, reason: 'token_budget' };
  }
  if (params.perSessionCap > 0 && params.sessionCount >= params.perSessionCap) {
    return { allowed: false, reason: 'session_cap' };
  }
  if (params.minuteCount >= maxPerMinute) {
    return { allowed: false, reason: 'rate_limit_minute', retryAfterSeconds: 60 };
  }
  if (params.dayCount >= maxPerDay) {
    return { allowed: false, reason: 'rate_limit_day', retryAfterSeconds: 3600 };
  }
  return { allowed: true };
}

/**
 * Atomically checks and increments per-user/session rate limits and daily token budget.
 */
export async function checkAndIncrementRateLimit(
  db: admin.firestore.Firestore,
  params: {
    sessionId: string;
    uid: string;
    dateKey: string;
    perSessionCap: number;
    dailyTokenBudget: number;
  }
): Promise<RateLimitResult> {
  const now = Date.now();
  const minuteBucket = Math.floor(now / 60000);
  const rateRef = db.collection('chatbot_rate_limits').doc(`${params.uid}_${params.dateKey}`);
  const sessionRef = db.collection('chatbot_sessions').doc(params.sessionId);
  const statsRef = db.collection('chatbot_stats_daily').doc(params.dateKey);

  return db.runTransaction(async (tx) => {
    const [rateSnap, sessionSnap, statsSnap] = await Promise.all([
      tx.get(rateRef),
      tx.get(sessionRef),
      tx.get(statsRef),
    ]);

    const rateData = rateSnap.data() ?? {};
    const storedMinuteBucket = rateData.minuteBucket as number | undefined;
    const minuteCount = storedMinuteBucket === minuteBucket ? (rateData.minuteCount as number) || 0 : 0;
    const dayCount = (rateData.dayCount as number) || 0;
    const sessionCount = (sessionSnap.data()?.messageCount as number) || 0;
    const dailyTokensUsed = (statsSnap.data()?.tokens as number) || 0;

    const evaluation = evaluateRateCounters({
      minuteCount,
      dayCount,
      sessionCount,
      dailyTokensUsed,
      perSessionCap: params.perSessionCap,
      dailyTokenBudget: params.dailyTokenBudget,
    });

    if (!evaluation.allowed) {
      return evaluation;
    }

    tx.set(
      rateRef,
      {
        uid: params.uid,
        dateKey: params.dateKey,
        minuteBucket,
        minuteCount: minuteCount + 1,
        dayCount: dayCount + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { allowed: true };
  });
}
