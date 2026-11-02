// Course-supplied transport; your agent owns document state and tool results.
export class LSPClient {
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
