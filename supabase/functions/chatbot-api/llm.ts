export interface ChatHistoryTurn {
  role: 'user' | 'assistant';
  text: string;
}

export interface LlmGenerateParams {
  systemInstruction: string;
  userPrompt: string;
  history: ChatHistoryTurn[];
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

const EMBEDDING_DIM = 768;

/**
 * Deterministic 768-dim Unicode word + bigram feature-hashing embedding.
 * Used as a zero-cost fallback for chat-only free providers like Groq/OpenRouter.
 */
function localHashEmbed(text: string): number[] {
  const vec = new Float64Array(EMBEDDING_DIM);
  const norm = text
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  if (!norm) {
    vec[0] = 1;
    return Array.from(vec);
  }
  const tokens = norm.split(' ').filter((t) => t.length > 1);
  const addFeature = (feat: string, weight: number) => {
    let h1 = 2166136261;
    let h2 = 0x811c9dc5;
    for (let i = 0; i < feat.length; i++) {
      const c = feat.charCodeAt(i);
      h1 = Math.imul(h1 ^ c, 16777619);
      h2 = Math.imul(h2 ^ (c + 31), 16777619);
    }
    const idx = (h1 >>> 0) % EMBEDDING_DIM;
    const sign = (h2 & 1) === 0 ? 1 : -1;
    vec[idx] += sign * weight;
  };

  for (let i = 0; i < tokens.length; i++) {
    addFeature(`w:${tokens[i]}`, 1.5);
    if (i + 1 < tokens.length) {
      addFeature(`b:${tokens[i]}_${tokens[i + 1]}`, 1.0);
    }
    for (let j = 0; j + 3 <= tokens[i].length; j++) {
      addFeature(`c:${tokens[i].slice(j, j + 3)}`, 0.4);
    }
  }

  let mag = 0;
  for (let i = 0; i < EMBEDDING_DIM; i++) mag += vec[i] * vec[i];
  mag = Math.sqrt(mag) || 1;
  const out = new Array<number>(EMBEDDING_DIM);
  for (let i = 0; i < EMBEDDING_DIM; i++) out[i] = vec[i] / mag;
  return out;
}

class GeminiProvider implements LlmProvider {
  readonly providerName = 'gemini';
  constructor(
    private apiKey: string,
    private chatModel = 'gemini-2.0-flash',
  ) {}

  async generateAnswer(params: LlmGenerateParams): Promise<LlmGenerateResult> {
    const contents = [
      ...params.history.slice(-6).map((h) => ({
        role: h.role === 'assistant' ? 'model' : 'user',
        parts: [{ text: h.text }],
      })),
      { role: 'user', parts: [{ text: params.userPrompt }] },
    ];

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.chatModel}:generateContent?key=${this.apiKey}`;
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: params.systemInstruction }] },
        contents,
        generationConfig: {
          temperature: params.temperature,
          maxOutputTokens: params.maxOutputTokens ?? 800,
        },
      }),
    });

    if (!res.ok) {
      throw new Error(`Gemini generateContent failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    const text =
      json?.candidates?.[0]?.content?.parts?.map((p: { text?: string }) => p.text ?? '').join('').trim() ?? '';
    const usage = json?.usageMetadata;
    return {
      text,
      tokensIn: usage?.promptTokenCount ?? Math.ceil(params.userPrompt.length / 4),
      tokensOut: usage?.candidatesTokenCount ?? Math.ceil(text.length / 4),
      model: this.chatModel,
    };
  }

  async embedText(text: string): Promise<number[]> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=${this.apiKey}`;
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'models/text-embedding-004',
        content: { parts: [{ text }] },
      }),
    });
    if (!res.ok) {
      throw new Error(`Gemini embedContent failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    const values: number[] = json?.embedding?.values ?? [];
    if (values.length !== EMBEDDING_DIM) {
      throw new Error(`Unexpected Gemini embedding dimension: ${values.length}`);
    }
    return values;
  }
}

class OpenAIProvider implements LlmProvider {
  readonly providerName = 'openai';
  constructor(
    private apiKey: string,
    private chatModel = 'gpt-4o-mini',
  ) {}

  async generateAnswer(params: LlmGenerateParams): Promise<LlmGenerateResult> {
    const messages = [
      { role: 'system', content: params.systemInstruction },
      ...params.history.slice(-6).map((h) => ({ role: h.role, content: h.text })),
      { role: 'user', content: params.userPrompt },
    ];

    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: this.chatModel,
        messages,
        temperature: params.temperature,
        max_tokens: params.maxOutputTokens ?? 800,
      }),
    });
    if (!res.ok) {
      throw new Error(`OpenAI chat failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    const text = json?.choices?.[0]?.message?.content?.trim() ?? '';
    return {
      text,
      tokensIn: json?.usage?.prompt_tokens ?? Math.ceil(params.userPrompt.length / 4),
      tokensOut: json?.usage?.completion_tokens ?? Math.ceil(text.length / 4),
      model: this.chatModel,
    };
  }

  async embedText(text: string): Promise<number[]> {
    const res = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'text-embedding-3-small',
        input: text,
        dimensions: EMBEDDING_DIM,
      }),
    });
    if (!res.ok) {
      throw new Error(`OpenAI embeddings failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    return json?.data?.[0]?.embedding ?? [];
  }
}

class ClaudeProvider implements LlmProvider {
  readonly providerName = 'claude';
  constructor(
    private apiKey: string,
    private embedDelegate: LlmProvider,
    private chatModel = 'claude-3-5-haiku-latest',
  ) {}

  async generateAnswer(params: LlmGenerateParams): Promise<LlmGenerateResult> {
    const messages = [
      ...params.history.slice(-6).map((h) => ({ role: h.role, content: h.text })),
      { role: 'user', content: params.userPrompt },
    ];

    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': this.apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: this.chatModel,
        system: params.systemInstruction,
        messages,
        temperature: params.temperature,
        max_tokens: params.maxOutputTokens ?? 800,
      }),
    });
    if (!res.ok) {
      throw new Error(`Anthropic messages failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    const text = (json?.content ?? [])
      .filter((b: { type?: string }) => b.type === 'text')
      .map((b: { text?: string }) => b.text ?? '')
      .join('\n')
      .trim();

    return {
      text,
      tokensIn: json?.usage?.input_tokens ?? Math.ceil(params.userPrompt.length / 4),
      tokensOut: json?.usage?.output_tokens ?? Math.ceil(text.length / 4),
      model: this.chatModel,
    };
  }

  async embedText(text: string): Promise<number[]> {
    return this.embedDelegate.embedText(text);
  }
}

class OpenAICompatibleChatProvider implements LlmProvider {
  constructor(
    readonly providerName: string,
    private apiKey: string,
    private endpoint: string,
    private chatModel: string,
    private modelsEndpoint?: string,
  ) {}

  private async callChat(model: string, params: LlmGenerateParams): Promise<Response> {
    const messages = [
      { role: 'system', content: params.systemInstruction },
      ...params.history.slice(-6).map((h) => ({ role: h.role, content: h.text })),
      { role: 'user', content: params.userPrompt },
    ];

    return await fetch(this.endpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        messages,
        temperature: params.temperature,
        max_tokens: params.maxOutputTokens ?? 800,
      }),
    });
  }

  private async pickAvailableModel(): Promise<string | null> {
    if (!this.modelsEndpoint) return null;
    try {
      const res = await fetch(this.modelsEndpoint, {
        headers: { Authorization: `Bearer ${this.apiKey}` },
      });
      if (!res.ok) return null;
      const json = await res.json();
      const ids: string[] = (json?.data ?? [])
        .map((m: { id?: string }) => String(m.id ?? ''))
        .filter((id: string) =>
          id.length > 0 &&
          !id.includes('whisper') &&
          !id.includes('tts') &&
          !id.includes('guard') &&
          !id.includes('safeguard') &&
          !id.includes('orpheus'),
        );
      const preferred = [
        'llama-3.1-8b-instant',
        'llama-3.3-70b-versatile',
        'meta-llama/llama-4-scout-17b-16e-instruct',
        'qwen/qwen3-32b',
        'gemma2-9b-it',
      ];
      for (const p of preferred) {
        if (ids.includes(p)) return p;
      }
      return ids[0] ?? null;
    } catch {
      return null;
    }
  }

  async generateAnswer(params: LlmGenerateParams): Promise<LlmGenerateResult> {
    let usedModel = this.chatModel;
    let res = await this.callChat(usedModel, params);
    if (res.status === 404 && this.modelsEndpoint) {
      const fallbackModel = await this.pickAvailableModel();
      if (fallbackModel && fallbackModel !== usedModel) {
        usedModel = fallbackModel;
        res = await this.callChat(usedModel, params);
      }
    }
    if (!res.ok) {
      throw new Error(`${this.providerName} chat failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    const text = json?.choices?.[0]?.message?.content?.trim() ?? '';
    return {
      text,
      tokensIn: json?.usage?.prompt_tokens ?? Math.ceil(params.userPrompt.length / 4),
      tokensOut: json?.usage?.completion_tokens ?? Math.ceil(text.length / 4),
      model: usedModel,
    };
  }

  async embedText(text: string): Promise<number[]> {
    return localHashEmbed(text);
  }
}

export function createLlmProviderFromEnv(): LlmProvider {
  const apiKey = Deno.env.get('LLM_API_KEY') ?? '';
  if (!apiKey) {
    throw new Error('LLM_API_KEY secret is not configured in Supabase.');
  }
  let provider = (Deno.env.get('LLM_PROVIDER') ?? '').toLowerCase().trim();
  if (!provider) {
    if (apiKey.startsWith('gsk_')) provider = 'groq';
    else if (apiKey.startsWith('sk-or-')) provider = 'openrouter';
    else if (apiKey.startsWith('sk-ant-')) provider = 'claude';
    else if (apiKey.startsWith('sk-')) provider = 'openai';
    else provider = 'gemini';
  }

  if (provider === 'groq') {
    return new OpenAICompatibleChatProvider(
      'groq',
      apiKey,
      'https://api.groq.com/openai/v1/chat/completions',
      Deno.env.get('LLM_MODEL') || 'llama-3.1-8b-instant',
      'https://api.groq.com/openai/v1/models',
    );
  }
  if (provider === 'openrouter') {
    return new OpenAICompatibleChatProvider(
      'openrouter',
      apiKey,
      'https://openrouter.ai/api/v1/chat/completions',
      'meta-llama/llama-3.3-70b-instruct:free',
    );
  }
  if (provider === 'openai') {
    return new OpenAIProvider(apiKey);
  }
  if (provider === 'claude' || provider === 'anthropic') {
    const embedKey = Deno.env.get('EMBEDDING_API_KEY') ?? apiKey;
    const embedDelegate = embedKey.startsWith('sk-')
      ? new OpenAIProvider(embedKey)
      : new GeminiProvider(embedKey);
    return new ClaudeProvider(apiKey, embedDelegate);
  }
  return new GeminiProvider(apiKey);
}
