// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied client for the language server the tester starts.

/**
 * Sends your agent's messages to the language server.
 *
 * The client doesn't track open documents or versions; that state belongs in
 * your agent.
 *
 * @property {Record<string, string>} extensionToLanguage Maps file extensions,
 *   including the dot, to LSP language IDs, such as `{ ".py": "python" }`.
 *
 * @example
 * const lsp = await LSPClient.fromEnvironment();
 * if (lsp !== null) {
 *   const language = lsp.extensionToLanguage[".py"]; // "python"
 *   const result = await lsp.call("request", { method: "textDocument/definition", params });
 * }
 */
export class LSPClient {
  /**
   * Connects to the language server the tester configured.
   *
   * @returns {Promise<LSPClient | null>} The client, or null when no language
   *   server is configured.
   */
  static async fromEnvironment() {
    if (process.env.CODECRAFTERS_LSP_URL === undefined) return null;
    return LSPClient.create();
  }

  /**
   * Connects and reads the extension-to-language mapping.
   *
   * @returns {Promise<LSPClient>}
   */
  static async create() {
    const client = new LSPClient();
    const configuration = await client.call("configuration", {});
    client.extensionToLanguage = configuration.extensionToLanguage;
    return client;
  }

  constructor() {
    this.url = process.env.CODECRAFTERS_LSP_URL;
    if (!this.url) throw new Error("Run with the course LSP transport");
  }

  /**
   * Sends one action to the language server.
   *
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
   * @param {string} action "configuration", "notify", "request", or "notifications".
   * @param {object} payload The action's payload, as above.
   * @returns {Promise<any>} The decoded JSON response.
   * @throws {Error} The language server returned an error, timed out (5 seconds
   *   for a request), or exited. The message is the transport's JSON, such as
   *   `{"error":"language server exited before responding to textDocument/definition"}`.
   */
  async call(action, payload) {
    const response = await fetch(`${this.url}/${action}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(10000),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(JSON.stringify(result));
    return result;
  }

  /** Shortcut for `call("request", { method, params })`. */
  request(method, params) {
    return this.call("request", { method, params });
  }

  /** Shortcut for `call("notify", { method, params })`. */
  notify(method, params) {
    return this.call("notify", { method, params });
  }

  /** Shortcut for `call("notifications", { after, timeoutMs })`. */
  notifications(after = 0, timeoutMs = 0) {
    return this.call("notifications", { after, timeoutMs });
  }
}
