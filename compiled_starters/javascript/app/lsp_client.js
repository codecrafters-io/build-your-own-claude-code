// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied transport; your agent owns document state and tool results.
export class LSPClient {
  static async fromEnvironment() {
    if (process.env.CODECRAFTERS_LSP_URL === undefined) return null;
    return LSPClient.create();
  }

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

  request(method, params) {
    return this.call("request", { method, params });
  }

  notify(method, params) {
    return this.call("notify", { method, params });
  }

  notifications(after = 0, timeoutMs = 0) {
    return this.call("notifications", { after, timeoutMs });
  }
}
