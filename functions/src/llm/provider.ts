import { GoogleGenerativeAI } from '@google/generative-ai';
import OpenAI from 'openai';
import Anthropic from '@anthropic-ai/sdk';
import { LlmGenerateParams, LlmGenerateResult, LlmProvider } from '../types';

const EMBEDDING_DIM = 768;

/**
 * Gemini implementation of LlmProvider.
 * Uses gemini-2.0-flash for generation and text-embedding-004 (768 dims) for embeddings.
 */
export class GeminiProvider implements LlmProvider {
  readonly providerName = 'gemini';
  private client: GoogleGenerativeAI;
  private chatModelName: string;

  constructor(apiKey: string, chatModelName = 'gemini-2.0-flash') {
    this.client = new GoogleGenerativeAI(apiKey);
    this.chatModelName = chatModelName;
  }

  async generateAnswer(params: LlmGenerateParams): Promise<LlmGenerateResult> {
    const model = this.client.getGenerativeModel({
      model: this.chatModelName,
      systemInstruction: params.systemInstruction,
      generationConfig: {
        temperature: params.temperature,
        maxOutputTokens: params.maxOutputTokens ?? 800,
      },
    });

    const contents = [
      ...params.history.slice(-6).map((h) => ({
        role: h.role === 'assistant' ? 'model' : 'user',
        parts: [{ text: h.text }],
      })),
      { role: 'user', parts: [{ text: params.userPrompt }] },
    ];

    const result = await model.generateContent({ contents });
    const response = result.response;
    const text = response.text().trim();
    const usage = response.usageMetadata;

    return {
      text,
      tokensIn: usage?.promptTokenCount ?? Math.ceil(params.userPrompt.length / 4),
      tokensOut: usage?.candidatesTokenCount ?? Math.ceil(text.length / 4),
      model: this.chatModelName,
    };
  }

  async embedText(text: string): Promise<number[]> {
    const embedModel = this.client.getGenerativeModel({ model: 'text-embedding-004' });
    const res = await embedModel.embedContent(text);
    const values = res.embedding?.values ?? [];
    if (values.length !== EMBEDDING_DIM) {
      throw new Error(`Unexpected Gemini embedding dimension: ${values.length}`);
    }
    return values;
  }
}

/**
 * OpenAI implementation of LlmProvider.
 * Uses gpt-4o-mini for generation and text-embedding-3-small (dimensions: 768) to match Firestore vector index.
 */
export class OpenAIProvider implements LlmProvider {
  readonly providerName = 'openai';
  private client: OpenAI;
  private chatModelName: string;

  constructor(apiKey: string, chatModelName = 'gpt-4o-mini') {
    this.client = new OpenAI({ apiKey });
    this.chatModelName = chatModelName;
  }

  async generateAnswer(params: LlmGenerateParams): Promise<LlmGenerateResult> {
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      { role: 'system', content: params.systemInstruction },
      ...params.history.slice(-6).map((h) => ({
        role: h.role as 'user' | 'assistant',
        content: h.text,
      })),
      { role: 'user', content: params.userPrompt },
    ];

    const completion = await this.client.chat.completions.create({
      model: this.chatModelName,
      messages,
      temperature: params.temperature,
      max_tokens: params.maxOutputTokens ?? 800,
    });

    const text = completion.choices[0]?.message?.content?.trim() ?? '';
    return {
      text,
      tokensIn: completion.usage?.prompt_tokens ?? Math.ceil(params.userPrompt.length / 4),
      tokensOut: completion.usage?.completion_tokens ?? Math.ceil(text.length / 4),
      model: this.chatModelName,
    };
  }

  async embedText(text: string): Promise<number[]> {
    const res = await this.client.embeddings.create({
      model: 'text-embedding-3-small',
      input: text,
      dimensions: EMBEDDING_DIM,
    });
    return res.data[0].embedding;
  }
}

/**
 * Anthropic Claude implementation of LlmProvider.
 * Note: Anthropic does not offer a native embedding endpoint, so it pairs Claude chat
 * with Gemini/OpenAI embeddings if an embedding key is provided.
 */
export class ClaudeProvider implements LlmProvider {
  readonly providerName = 'claude';
  private client: Anthropic;
  private chatModelName: string;
  private embedDelegate: LlmProvider;

  constructor(apiKey: string, embedDelegate: LlmProvider, chatModelName = 'claude-3-5-haiku-latest') {
    this.client = new Anthropic({ apiKey });
    this.chatModelName = chatModelName;
    this.embedDelegate = embedDelegate;
  }

  async generateAnswer(params: LlmGenerateParams): Promise<LlmGenerateResult> {
    const messages: Anthropic.MessageParam[] = [
      ...params.history.slice(-6).map((h) => ({
        role: h.role as 'user' | 'assistant',
        content: h.text,
      })),
      { role: 'user', content: params.userPrompt },
    ];

    const response = await this.client.messages.create({
      model: this.chatModelName,
      system: params.systemInstruction,
      messages,
      temperature: params.temperature,
      max_tokens: params.maxOutputTokens ?? 800,
    });

    const textBlock = response.content.find((c) => c.type === 'text');
    const text = textBlock && textBlock.type === 'text' ? textBlock.text.trim() : '';

    return {
      text,
      tokensIn: response.usage.input_tokens,
      tokensOut: response.usage.output_tokens,
      model: this.chatModelName,
    };
  }

  async embedText(text: string): Promise<number[]> {
    return this.embedDelegate.embedText(text);
  }
}

/**
 * Factory to instantiate the configured LlmProvider from Secret Manager / env.
 */
export function createLlmProvider(
  providerName: string,
  apiKey: string,
  secondaryEmbedKey?: string
): LlmProvider {
  const normalized = (providerName || 'gemini').toLowerCase().trim();
  if (normalized === 'openai') {
    return new OpenAIProvider(apiKey);
  }
  if (normalized === 'claude' || normalized === 'anthropic') {
    const embedKey = secondaryEmbedKey || apiKey;
    return new ClaudeProvider(apiKey, new GeminiProvider(embedKey));
  }
  return new GeminiProvider(apiKey);
}
