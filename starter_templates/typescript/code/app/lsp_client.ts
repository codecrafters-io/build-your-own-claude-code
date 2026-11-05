// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied transport; your agent owns document state and tool results.
export class LSPClient {
  private url: string;
  extensionToLanguage!: Record<string, string>;

  static async fromEnvironment(): Promise<LSPClient | null> {
    if (process.env.CODECRAFTERS_LSP_URL === undefined) return null;
    return LSPClient.create();
  }

  private constructor() {
    const url = process.env.CODECRAFTERS_LSP_URL;
    if (!url) throw new Error("Run with the course LSP transport");
    this.url = url;
  }

  static async create(): Promise<LSPClient> {
    const client = new LSPClient();
    const configuration = await client.call("configuration", {}) as {
      extensionToLanguage: Record<string, string>;
    };
    client.extensionToLanguage = configuration.extensionToLanguage;
    return client;
  }

  async call(action: string, payload: unknown): Promise<unknown> {
    const response = await fetch(`${this.url}/${action}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(10000),
    });
    const result: unknown = await response.json();
    if (!response.ok) throw new Error(JSON.stringify(result));
    return result;
  }

  request(method: string, params: unknown) {
    return this.call("request", { method, params });
  }

  notify(method: string, params: unknown) {
    return this.call("notify", { method, params });
  }

  notifications(after = 0, timeoutMs = 0) {
    return this.call("notifications", { after, timeoutMs });
  }
}
