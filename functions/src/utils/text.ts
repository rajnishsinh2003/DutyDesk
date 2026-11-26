/**
 * Text processing, chunking, PII masking, and prompt-injection guards.
 */

export function sanitizeUserInput(text: string, maxLength = 500): string {
  if (!text) return '';
  // Strip control characters except newlines/tabs, collapse excessive whitespace
  const cleaned = text
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
    .trim();
  return cleaned.length > maxLength ? cleaned.slice(0, maxLength) : cleaned;
}

/**
 * Masks sensitive PII (phone numbers, email addresses, Aadhaar/PAN/Resource IDs)
 * before persisting user queries to Firestore logs or unanswered queues.
 */
export function maskPII(text: string): string {
  if (!text) return '';
  let masked = text;

  // Mask email addresses
  masked = masked.replace(
    /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g,
    '[EMAIL_REDACTED]'
  );

  // Mask Indian/international phone numbers (10+ digits, optional +91 / spaces / dashes)
  masked = masked.replace(
    /(?:\+?\d{1,3}[-.\s]?)?(?:\(?\d{3,5}\)?[-.\s]?)?\d{5}[-.\s]?\d{5}\b/g,
    '[PHONE_REDACTED]'
  );
  masked = masked.replace(/\b[6-9]\d{9}\b/g, '[PHONE_REDACTED]');

  // Mask 12-digit Aadhaar-like numbers (xxxx xxxx xxxx or 12 consecutive digits)
  masked = masked.replace(/\b\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g, '[ID_REDACTED]');

  // Mask PAN-like patterns (ABCDE1234F)
  masked = masked.replace(/\b[A-Z]{5}\d{4}[A-Z]\b/g, '[PAN_REDACTED]');

  return masked;
}

/**
 * Detects prompt-injection attempts trying to override instructions or extract system prompts.
 */
export function detectPromptInjection(text: string): boolean {
  const lower = text.toLowerCase();
  const patterns = [
    /ignore\s+(all\s+)?(previous|prior|above)\s+instructions/i,
    /disregard\s+(your\s+)?(system|previous)\s+(prompt|instructions)/i,
    /reveal\s+(your\s+)?(system\s+prompt|instructions|rules)/i,
    /what\s+(is|are)\s+your\s+system\s+(prompt|instructions)/i,
    /you\s+are\s+now\s+(dan|developer\s+mode|unrestricted)/i,
    /jailbreak/i,
    /print\s+your\s+api\s+key/i,
  ];
  return patterns.some((rx) => rx.test(lower));
}

/**
 * Normalizes a question for grouping in chatbot_unanswered.
 */
export function normalizeQuestion(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Detects language ('en', 'hi', 'gu') from script characters, falling back to app locale.
 */
export function resolveReplyLanguage(question: string, appLocale?: string): 'en' | 'hi' | 'gu' {
  // Devanagari Unicode block (Hindi)
  if (/[\u0900-\u097F]/.test(question)) {
    return 'hi';
  }
  // Gujarati Unicode block
  if (/[\u0A80-\u0AFF]/.test(question)) {
    return 'gu';
  }
  if (appLocale === 'hi' || appLocale === 'gu') {
    return appLocale;
  }
  return 'en';
}

/**
 * Splits extracted document text into overlapping chunks (~500-800 tokens, 100 overlap).
 * Uses ~4 chars per token approximation, preferring paragraph/sentence boundaries.
 */
export function chunkText(
  rawText: string,
  targetTokens = 650,
  overlapTokens = 100
): string[] {
  const cleaned = rawText
    .replace(/\r\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t]{2,}/g, ' ')
    .trim();

  if (!cleaned) return [];

  const targetChars = targetTokens * 4; // ~2600 chars
  const overlapChars = overlapTokens * 4; // ~400 chars

  if (cleaned.length <= targetChars) {
    return [cleaned];
  }

  const chunks: string[] = [];
  let start = 0;

  while (start < cleaned.length) {
    let end = Math.min(start + targetChars, cleaned.length);

    // Try to snap to a sentence or paragraph boundary if not at end of text
    if (end < cleaned.length) {
      const slice = cleaned.slice(start, end);
      const lastParagraph = slice.lastIndexOf('\n\n');
      const lastSentence = Math.max(
        slice.lastIndexOf('. '),
        slice.lastIndexOf('? '),
        slice.lastIndexOf('! '),
        slice.lastIndexOf('।\n'),
        slice.lastIndexOf('। ')
      );
      const minBreak = Math.floor(targetChars * 0.5);

      if (lastParagraph > minBreak) {
        end = start + lastParagraph + 2;
      } else if (lastSentence > minBreak) {
        end = start + lastSentence + 2;
      } else {
        const lastSpace = slice.lastIndexOf(' ');
        if (lastSpace > minBreak) {
          end = start + lastSpace + 1;
        }
      }
    }

    const chunk = cleaned.slice(start, end).trim();
    if (chunk.length > 0) {
      chunks.push(chunk);
    }

    if (end >= cleaned.length) break;

    const nextStart = end - overlapChars;
    start = nextStart > start ? nextStart : end;
  }

  return chunks;
}
