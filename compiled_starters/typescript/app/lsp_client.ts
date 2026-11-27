// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied client for the language server the tester starts.

/**
 * Sends your agent's messages to the language server.
 *
 * @remarks
 * The client doesn't track open documents or versions; that state belongs in
 * your agent.
 *
 * @example
 * ```ts
 * const lsp = await LSPClient.fromEnvironment();
 * if (lsp !== null) {
 *   const language = lsp.extensionToLanguage[".py"]; // "python"
 *   const result = await lsp.call("request", { method: "textDocument/definition", params });
 * }
 * ```
 */
export class LSPClient {
  private url: string;
  /** Maps file extensions, including the dot, to LSP language IDs, such as `{ ".py": "python" }`. */
  extensionToLanguage!: Record<string, string>;

  /**
   * Connects to the language server the tester configured.
   *
   * @returns The client, or null when no language server is configured.
   */
  static async fromEnvironment(): Promise<LSPClient | null> {
    if (process.env.CODECRAFTERS_LSP_URL === undefined) return null;
    return LSPClient.create();
  }

  private constructor() {
    const url = process.env.CODECRAFTERS_LSP_URL;
    if (!url) throw new Error("Run with the course LSP transport");
    this.url = url;
  }

  /** Connects and reads the extension-to-language mapping. */
  static async create(): Promise<LSPClient> {
    const client = new LSPClient();
    const configuration = await client.call("configuration", {}) as {
      extensionToLanguage: Record<string, string>;
    };
    client.extensionToLanguage = configuration.extensionToLanguage;
    return client;
  }

  /**
   * Sends one action to the language server.
   *
   * @remarks
   * Actions and their payloads:
   * - "configuration": `{}`. Returns `{ extensionToLanguage: { ".py": "python" } }`.
   * - "notify": `{ method, params }`, an LSP notification. Returns null.
   * - "request": `{ method, params }`, an LSP request. Returns the server's
   *   result, which may be null, an object, or an array.
   * - "notifications": `{ after, timeoutMs }`. Returns `{ cursor, notifications }`:
   *   the server's notifications after the `after` cursor, each with `method`
   *   and `params`. Waits up to `timeoutMs` (0 to 5000) when none are queued
   *   yet. Pass the returned `cursor` as `after` next time.
   *
   * @param action - "configuration", "notify", "request", or "notifications".
   * @param payload - The action's payload, as above.
   * @returns The decoded JSON response. Cast it to the shape you expect.
   * @throws Error when the language server returns an error, times out (5
   *   seconds for a request), or exits. The message is the transport's JSON,
   *   such as `{"error":"language server exited before responding to textDocument/definition"}`.
   */
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

  /** Shortcut for `call("request", { method, params })`. */
  request(method: string, params: unknown) {
    return this.call("request", { method, params });
  }

  /** Shortcut for `call("notify", { method, params })`. */
  notify(method: string, params: unknown) {
    return this.call("notify", { method, params });
  }

  /** Shortcut for `call("notifications", { after, timeoutMs })`. */
  notifications(after = 0, timeoutMs = 0) {
    return this.call("notifications", { after, timeoutMs });
  }
}
