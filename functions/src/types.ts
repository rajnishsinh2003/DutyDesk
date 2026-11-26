import * as admin from 'firebase-admin';

export type Audience = 'public' | 'invigilator' | 'admin';
export type Surface = 'landing' | 'invigilator';
export type SupportedLocale = 'en' | 'hi' | 'gu';

export interface ChatbotSettings {
  landingEnabled: boolean;
  invigilatorEnabled: boolean;
  botName: string;
  welcomeMessage: Record<string, string>;
  pinnedAnnouncement: string;
  suggestedQuestions: {
    landing: Record<string, string[]>;
    invigilator: Record<string, string[]>;
  };
  fallbackMessage: Record<string, string>;
  systemPromptAdditions: string;
  answerOnlyFromDocuments: boolean;
  similarityThreshold: number;
  temperature: number;
  maxInputLength: number;
  perSessionMessageCap: number;
  dailyTokenBudget: number;
  retentionDays: number;
  handoffContact: {
    phone: string;
    whatsapp: string;
    email: string;
  };
}

export interface RetrievedSource {
  docId: string;
  title: string;
  chunkId: string;
  score: number;
  excerpt?: string;
  isFaq?: boolean;
}

export interface ChatAskRequest {
  sessionId: string;
  message: string;
  surface: Surface;
  locale?: string;
  userContext?: {
    userType?: 'visitor' | 'invigilator';
    userId?: string;
    userName?: string;
    platform?: string;
  };
}

export interface ChatAskResponse {
  answer: string;
  sources: RetrievedSource[];
  messageId: string;
  answered: boolean;
  confidence: number;
  fallbackReason?: string;
}

export interface LlmGenerateParams {
  systemInstruction: string;
  userPrompt: string;
  history: Array<{ role: 'user' | 'assistant'; text: string }>;
  temperature: number;
  maxOutputTokens?: number;
}

export interface LlmGenerateResult {
  text: string;
  tokensIn: number;
  tokensOut: number;
  model: string;
}

export interface LlmProvider {
  readonly providerName: string;
  generateAnswer(params: LlmGenerateParams): Promise<LlmGenerateResult>;
  embedText(text: string): Promise<number[]>;
}

export interface ChatbotDocumentRecord {
  title: string;
  description?: string;
  category: string;
  audience: Audience[];
  sourceType: 'file' | 'text' | 'faq';
  storagePath?: string;
  rawText?: string;
  mimeType?: string;
  sizeBytes?: number;
  status: 'uploaded' | 'processing' | 'ready' | 'failed';
  error?: string;
  chunkCount: number;
  enabled: boolean;
  version: number;
  uploadedBy: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}
