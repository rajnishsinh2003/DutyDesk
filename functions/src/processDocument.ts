import * as admin from 'firebase-admin';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import pdfParse from 'pdf-parse';
import mammoth from 'mammoth';
import { createLlmProvider } from './llm/provider';
import { llmApiKey, llmProviderName } from './chatAsk';
import { chunkText } from './utils/text';
import { Audience } from './types';

function assertAdmin(request: { auth?: { uid: string; token: Record<string, unknown> } }): string {
  if (!request.auth || request.auth.token?.admin !== true) {
    throw new HttpsError('permission-denied', 'Admin custom claim is required.');
  }
  return request.auth.uid;
}

async function extractTextFromBuffer(buffer: Buffer, mimeType: string, storagePath: string): Promise<string> {
  const lowerMime = (mimeType || '').toLowerCase();
  const lowerPath = (storagePath || '').toLowerCase();

  if (lowerMime.includes('pdf') || lowerPath.endsWith('.pdf')) {
    const parsed = await pdfParse(buffer);
    return parsed.text || '';
  }

  if (
    lowerMime.includes('wordprocessingml') ||
    lowerMime.includes('msword') ||
    lowerPath.endsWith('.docx')
  ) {
    const result = await mammoth.extractRawText({ buffer });
    return result.value || '';
  }

  // Plain text / markdown / CSV
  return buffer.toString('utf8');
}

async function deleteDocumentChunks(db: admin.firestore.Firestore, docId: string): Promise<number> {
  let totalDeleted = 0;
  while (true) {
    const snap = await db.collection('chatbot_chunks').where('docId', '==', docId).limit(400).get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const d of snap.docs) {
      batch.delete(d.ref);
    }
    await batch.commit();
    totalDeleted += snap.size;
  }
  return totalDeleted;
}

async function processDocumentCore(docId: string): Promise<number> {
  const db = admin.firestore();
  const docRef = db.collection('chatbot_documents').doc(docId);
  const snap = await docRef.get();
  if (!snap.exists) {
    throw new Error(`Document ${docId} does not exist.`);
  }

  const data = snap.data()!;
  await docRef.update({
    status: 'processing',
    error: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    let rawText = (data.rawText as string) || '';

    if (data.sourceType === 'file') {
      const storageUrl = data.storageUrl as string | undefined;
      if (!storageUrl) {
        throw new Error('Missing storageUrl for file document.');
      }
      const resp = await fetch(storageUrl);
      if (!resp.ok) {
        throw new Error(`Failed to download file from Supabase (${resp.status} ${resp.statusText})`);
      }
      const arrayBuf = await resp.arrayBuffer();
      const buffer = Buffer.from(arrayBuf);
      rawText = await extractTextFromBuffer(
        buffer,
        (data.mimeType as string) || '',
        (data.storagePath as string) || storageUrl
      );
    }

    const cleanedText = rawText.trim();
    if (!cleanedText) {
      throw new Error('No readable text could be extracted from this document.');
    }

    const chunks = chunkText(cleanedText, 650, 100);
    if (chunks.length === 0) {
      throw new Error('Document produced zero valid text chunks.');
    }

    // Delete any existing chunks first (idempotent re-indexing)
    await deleteDocumentChunks(db, docId);

    const llm = createLlmProvider(llmProviderName.value(), llmApiKey.value());
    const audience: Audience[] = Array.isArray(data.audience) && data.audience.length > 0
      ? data.audience
      : ['public'];
    const enabled = data.enabled !== false;

    // Generate embeddings & write chunks in batches of 200
    let batch = db.batch();
    let batchCount = 0;

    for (let i = 0; i < chunks.length; i++) {
      const chunkContent = chunks[i];
      const embedding = await llm.embedText(chunkContent);
      const chunkRef = db.collection('chatbot_chunks').doc(`${docId}_chunk_${i}`);

      batch.set(chunkRef, {
        docId,
        index: i,
        text: chunkContent,
        embedding: admin.firestore.FieldValue.vector(embedding),
        audience,
        enabled,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      batchCount++;
      if (batchCount >= 200) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    await docRef.update({
      status: 'ready',
      chunkCount: chunks.length,
      error: admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return chunks.length;
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    await docRef.update({
      status: 'failed',
      error: message.slice(0, 500),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw err;
  }
}

/**
 * Triggered automatically when a new knowledge base document is created with status='uploaded'.
 */
export const onChatbotDocumentCreated = onDocumentCreated(
  {
    document: 'chatbot_documents/{docId}',
    region: 'asia-south1',
    secrets: [llmApiKey],
    timeoutSeconds: 300,
    memory: '1GiB',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    if (data.status === 'uploaded') {
      try {
        await processDocumentCore(event.params.docId);
      } catch (err) {
        console.error(`Failed processing document ${event.params.docId}:`, err);
      }
    }
  }
);

/**
 * Automatically generates/updates vector embedding when an FAQ is created or modified.
 */
export const onChatbotFaqWritten = onDocumentWritten(
  {
    document: 'chatbot_faqs/{faqId}',
    region: 'asia-south1',
    secrets: [llmApiKey],
  },
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return;

    const afterData = after.data()!;
    const beforeData = event.data?.before?.data();

    const textChanged =
      !beforeData ||
      beforeData.question !== afterData.question ||
      beforeData.answer !== afterData.answer ||
      !afterData.embedding;

    if (!textChanged) return;

    const llm = createLlmProvider(llmProviderName.value(), llmApiKey.value());
    const combined = `Question: ${afterData.question || ''}\nAnswer: ${afterData.answer || ''}`;
    const embedding = await llm.embedText(combined);

    await after.ref.update({
      embedding: admin.firestore.FieldValue.vector(embedding),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);

/**
 * Admin-only callable to re-extract, re-chunk, and re-embed an existing document.
 */
export const reindexDocument = onCall<{ docId: string }>(
  {
    region: 'asia-south1',
    secrets: [llmApiKey],
    timeoutSeconds: 300,
    memory: '1GiB',
  },
  async (request) => {
    const adminUid = assertAdmin(request);
    const docId = (request.data?.docId || '').trim();
    if (!docId) {
      throw new HttpsError('invalid-argument', 'docId is required.');
    }

    const chunkCount = await processDocumentCore(docId);

    await admin.firestore().collection('chatbot_audit').add({
      actorUid: adminUid,
      action: 'document_reindexed',
      targetId: docId,
      details: { chunkCount },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, chunkCount };
  }
);

/**
 * Admin-only callable to cascade-delete a document, its chunks, and its Storage file.
 */
export const deleteDocument = onCall<{ docId: string }>(
  { region: 'asia-south1' },
  async (request) => {
    const adminUid = assertAdmin(request);
    const docId = (request.data?.docId || '').trim();
    if (!docId) {
      throw new HttpsError('invalid-argument', 'docId is required.');
    }

    const db = admin.firestore();
    const docRef = db.collection('chatbot_documents').doc(docId);
    const snap = await docRef.get();

    if (snap.exists) {
      const storagePath = snap.data()?.storagePath as string | undefined;
      const storageUrl = snap.data()?.storageUrl as string | undefined;
      if (storagePath && storageUrl && storageUrl.includes('/storage/v1/object/')) {
        const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
        if (supabaseServiceKey) {
          try {
            const baseUrl = storageUrl.split('/storage/v1/object/')[0];
            await fetch(`${baseUrl}/storage/v1/object/chatbot-docs/${storagePath}`, {
              method: 'DELETE',
              headers: {
                Authorization: `Bearer ${supabaseServiceKey}`,
                apikey: supabaseServiceKey,
              },
            });
          } catch (err) {
            console.warn(`Supabase file delete skipped for ${storagePath}:`, err);
          }
        }
      }
      await docRef.delete();
    }

    const deletedChunks = await deleteDocumentChunks(db, docId);

    await db.collection('chatbot_audit').add({
      actorUid: adminUid,
      action: 'document_deleted',
      targetId: docId,
      details: { deletedChunks },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, deletedChunks };
  }
);
