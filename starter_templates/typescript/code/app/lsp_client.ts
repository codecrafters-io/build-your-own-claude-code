// Course-supplied transport; your agent owns document state and tool results.
export class LSPClient {
  private url: string;

  constructor() {
    const url = process.env.CODECRAFTERS_LSP_URL;
    if (!url) throw new Error("Run with the course LSP transport");
    this.url = url;
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
