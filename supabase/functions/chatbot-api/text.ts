import JSZip from 'npm:jszip@3.10.1';
import { extractText } from 'npm:unpdf@0.12.1';

export function sanitizeUserInput(raw: string, maxLength = 500): string {
  return raw
    .replace(/[\u0000-\u001F\u007F]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, maxLength);
}

export function maskPII(text: string): string {
  let masked = text;
  masked = masked.replace(
    /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g,
    '[EMAIL]',
  );
  masked = masked.replace(/(?:\+91[\s-]?)?[6-9]\d{9}\b/g, '[PHONE]');
  masked = masked.replace(/\b\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g, '[ID_NUMBER]');
  masked = masked.replace(/\b[A-Z]{5}\d{4}[A-Z]\b/g, '[ID_NUMBER]');
  return masked;
}

const INJECTION_PATTERNS: RegExp[] = [
  /ignore\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules)/i,
  /disregard\s+(your\s+)?(system\s+)?(prompt|instructions)/i,
  /reveal\s+(your\s+)?(system\s+prompt|instructions|rules)/i,
  /what\s+(is|are)\s+your\s+(system\s+prompt|hidden\s+instructions)/i,
  /you\s+are\s+now\s+(a|an|in)\s+developer\s+mode/i,
  /\bjailbreak\b/i,
  /<\s*\/?\s*system\s*>/i,
];

export function detectPromptInjection(text: string): boolean {
  return INJECTION_PATTERNS.some((re) => re.test(text));
}

export function normalizeQuestion(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function resolveReplyLanguage(question: string, appLocale = 'en'): 'en' | 'hi' | 'gu' {
  if (/[\u0A80-\u0AFF]/.test(question)) return 'gu';
  if (/[\u0900-\u097F]/.test(question)) return 'hi';
  const loc = appLocale.toLowerCase();
  if (loc.startsWith('gu')) return 'gu';
  if (loc.startsWith('hi')) return 'hi';
  return 'en';
}

export interface TextChunk {
  index: number;
  text: string;
}

export function chunkText(
  rawText: string,
  targetChars = 2200,
  overlapChars = 350,
): TextChunk[] {
  const cleaned = rawText
    .replace(/\r\n/g, '\n')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

  if (!cleaned) return [];
  if (cleaned.length <= targetChars) {
    return [{ index: 0, text: cleaned }];
  }

  const chunks: TextChunk[] = [];
  let start = 0;
  let idx = 0;

  while (start < cleaned.length) {
    let end = Math.min(start + targetChars, cleaned.length);
    if (end < cleaned.length) {
      const slice = cleaned.slice(start, end);
      const lastPara = slice.lastIndexOf('\n\n');
      const lastSentence = Math.max(slice.lastIndexOf('. '), slice.lastIndexOf('? '));
      const breakPoint = lastPara > targetChars * 0.5
        ? lastPara
        : lastSentence > targetChars * 0.5
        ? lastSentence + 1
        : -1;
      if (breakPoint > 0) {
        end = start + breakPoint;
      }
    }

    const piece = cleaned.slice(start, end).trim();
    if (piece.length > 0) {
      chunks.push({ index: idx++, text: piece });
    }
    if (end >= cleaned.length) break;
    start = Math.max(end - overlapChars, start + 1);
  }

  return chunks;
}

export async function extractDocumentText(
  bytes: Uint8Array,
  mimeType: string,
  fileName: string,
): Promise<string> {
  const lower = fileName.toLowerCase();
  if (mimeType === 'application/pdf' || lower.endsWith('.pdf')) {
    const result = await extractText(bytes, { mergePages: true });
    return (result.text ?? '').trim();
  }
  if (
    mimeType === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
    lower.endsWith('.docx')
  ) {
    const zip = await JSZip.loadAsync(bytes);
    const docXml = await zip.file('word/document.xml')?.async('string');
    if (!docXml) {
      throw new Error('Invalid DOCX file: word/document.xml not found.');
    }
    return docXml
      .replace(/<\/w:p>/g, '\n')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/\s+\n/g, '\n')
      .replace(/[ \t]+/g, ' ')
      .trim();
  }
  return new TextDecoder('utf-8').decode(bytes).trim();
}
