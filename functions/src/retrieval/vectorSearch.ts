import * as admin from 'firebase-admin';
import { Audience, RetrievedSource, Surface } from '../types';

export function getAllowedAudiences(surface: Surface): Audience[] {
  if (surface === 'invigilator') {
    return ['public', 'invigilator'];
  }
  return ['public'];
}

/**
 * Evaluates whether the retrieved sources meet the similarity threshold.
 */
export function evaluateRetrievalConfidence(
  sources: RetrievedSource[],
  similarityThreshold: number
): { isConfident: boolean; topScore: number } {
  if (sources.length === 0) {
    return { isConfident: false, topScore: 0 };
  }
  const topScore = Math.max(...sources.map((s) => s.score));
  return {
    isConfident: topScore >= similarityThreshold,
    topScore,
  };
}

/**
 * Searches approved FAQs first (priority), then document chunks via Firestore findNearest.
 * Strictly filters by `audience` so landing visitors only ever see `public` sources.
 */
export async function retrieveRelevantContext(
  db: admin.firestore.Firestore,
  queryEmbedding: number[],
  surface: Surface,
  similarityThreshold: number
): Promise<{
  sources: RetrievedSource[];
  topScore: number;
  isConfident: boolean;
  faqHit?: { id: string; question: string; answer: string; score: number };
}> {
  const allowedAudiences = getAllowedAudiences(surface);
  const vectorQuery = admin.firestore.FieldValue.vector(queryEmbedding);

  // 1. Search approved FAQs first (priority over document chunks)
  let faqHit: { id: string; question: string; answer: string; score: number } | undefined;
  const faqSources: RetrievedSource[] = [];

  try {
    const faqSnap = await db
      .collection('chatbot_faqs')
      .where('enabled', '==', true)
      .where('audience', 'array-contains-any', allowedAudiences)
      .findNearest('embedding', vectorQuery, {
        limit: 3,
        distanceMeasure: 'COSINE',
        distanceResultField: 'vector_distance',
      })
      .get();

    for (const doc of faqSnap.docs) {
      const data = doc.data();
      const distance = typeof data.vector_distance === 'number' ? data.vector_distance : 1;
      // Cosine similarity = 1 - cosine distance, clamped [0, 1]
      const score = Math.max(0, Math.min(1, 1 - distance));
      if (score >= similarityThreshold) {
        if (!faqHit || score > faqHit.score) {
          faqHit = {
            id: doc.id,
            question: data.question || '',
            answer: data.answer || '',
            score,
          };
        }
        faqSources.push({
          docId: doc.id,
          title: `FAQ: ${data.question || 'Official FAQ'}`,
          chunkId: doc.id,
          score: Number(score.toFixed(4)),
          excerpt: data.answer || '',
          isFaq: true,
        });
      }
    }
  } catch (err) {
    console.warn('FAQ vector search failed or index missing:', err);
  }

  // 2. Search document chunks filtered by audience
  const chunkSources: RetrievedSource[] = [];
  try {
    const chunkSnap = await db
      .collection('chatbot_chunks')
      .where('enabled', '==', true)
      .where('audience', 'array-contains-any', allowedAudiences)
      .findNearest('embedding', vectorQuery, {
        limit: 5,
        distanceMeasure: 'COSINE',
        distanceResultField: 'vector_distance',
      })
      .get();

    // Batch-fetch parent document titles
    const docIds = Array.from(new Set(chunkSnap.docs.map((d) => d.data().docId as string).filter(Boolean)));
    const titleMap = new Map<string, string>();

    if (docIds.length > 0) {
      const docRefs = docIds.map((id) => db.collection('chatbot_documents').doc(id));
      const docSnaps = await db.getAll(...docRefs);
      for (const snap of docSnaps) {
        if (snap.exists) {
          const dData = snap.data();
          if (dData?.enabled !== false) {
            titleMap.set(snap.id, dData?.title || 'DutyDesk Document');
          }
        }
      }
    }

    for (const doc of chunkSnap.docs) {
      const data = doc.data();
      const docId = data.docId as string;
      const title = titleMap.get(docId);
      if (!title) continue; // Skip if parent doc disabled or deleted

      const distance = typeof data.vector_distance === 'number' ? data.vector_distance : 1;
      const score = Math.max(0, Math.min(1, 1 - distance));

      chunkSources.push({
        docId,
        title,
        chunkId: doc.id,
        score: Number(score.toFixed(4)),
        excerpt: data.text || '',
        isFaq: false,
      });
    }
  } catch (err) {
    console.warn('Chunk vector search failed or index missing:', err);
  }

  // Combine with FAQs prioritized first
  const combined = [...faqSources, ...chunkSources]
    .sort((a, b) => (a.isFaq === b.isFaq ? b.score - a.score : a.isFaq ? -1 : 1))
    .slice(0, 5);

  const { isConfident, topScore } = evaluateRetrievalConfidence(combined, similarityThreshold);

  return {
    sources: combined,
    topScore,
    isConfident,
    faqHit,
  };
}
