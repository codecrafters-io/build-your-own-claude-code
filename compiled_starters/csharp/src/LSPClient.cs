// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied client for the language server the tester starts.
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

/// <summary>
/// Sends your agent's messages to the language server.
/// </summary>
/// <remarks>
/// The client doesn't track open documents or versions; that state belongs in
/// your agent. Payloads and responses are JSON text, so build and parse them
/// with your existing JSON library.
/// </remarks>
/// <example>
/// <code>
/// var lsp = await LSPClient.FromEnvironmentAsync();
/// if (lsp is not null) {
///     var language = lsp.ExtensionToLanguage[".py"]; // "python"
///     string result = await lsp.Call("request", requestJson);
/// }
/// </code>
/// </example>
public sealed class LSPClient
{
    private readonly string url = Environment.GetEnvironmentVariable("CODECRAFTERS_LSP_URL")
        ?? throw new InvalidOperationException("Run with the course LSP transport");
    private static readonly HttpClient client = new HttpClient { Timeout = TimeSpan.FromSeconds(10) };
    /// <summary>
    /// Maps file extensions, including the dot, to LSP language IDs, such as
    /// <c>{".py": "python"}</c>.
    /// </summary>
    public IReadOnlyDictionary<string, string> ExtensionToLanguage { get; private set; } = null!;

    private LSPClient() {}

    /// <summary>Connects to the language server the tester configured.</summary>
    /// <returns>The client, or <c>null</c> when no language server is configured.</returns>
    public static async Task<LSPClient?> FromEnvironmentAsync()
    {
        if (Environment.GetEnvironmentVariable("CODECRAFTERS_LSP_URL") == null) return null;
        return await CreateAsync();
    }

    /// <summary>Connects and reads the extension-to-language mapping.</summary>
    public static async Task<LSPClient> CreateAsync()
    {
        var lsp = new LSPClient();
        var configurationJson = await lsp.Call("configuration", "{}");
        using var configuration = JsonDocument.Parse(configurationJson);
        lsp.ExtensionToLanguage = configuration.RootElement.GetProperty("extensionToLanguage")
            .Deserialize<Dictionary<string, string>>()!;
        return lsp;
    }

    /// <summary>Sends one action to the language server.</summary>
    /// <remarks>
    /// Actions and their payloads:
    /// <list type="bullet">
    /// <item><c>"configuration"</c>: <c>{}</c>. Returns
    /// <c>{"extensionToLanguage": {".py": "python"}}</c>.</item>
    /// <item><c>"notify"</c>: <c>{"method": ..., "params": {...}}</c>, an LSP
    /// notification. Returns <c>null</c> as JSON text.</item>
    /// <item><c>"request"</c>: <c>{"method": ..., "params": {...}}</c>, an LSP
    /// request. Returns the server's result, which may be <c>null</c>, an
    /// object, or an array.</item>
    /// <item><c>"notifications"</c>: <c>{"after": cursor, "timeoutMs": ms}</c>.
    /// Returns <c>{"cursor": n, "notifications": [...]}</c>: the server's
    /// notifications after the cursor, each with <c>method</c> and
    /// <c>params</c>. Waits up to <c>ms</c> (0 to 5000) when none are queued
    /// yet. Pass the returned cursor as <c>after</c> next time.</item>
    /// </list>
    /// </remarks>
    /// <param name="action"><c>"configuration"</c>, <c>"notify"</c>, <c>"request"</c>, or <c>"notifications"</c>.</param>
    /// <param name="json">The action's payload as JSON text, as above.</param>
    /// <returns>The response as JSON text.</returns>
    /// <exception cref="InvalidOperationException">
    /// The language server returned an error, timed out (5 seconds for a
    /// request), or exited. The message is the transport's JSON, such as
    /// <c>{"error":"language server exited before responding to textDocument/definition"}</c>.
    /// </exception>
    public async Task<string> Call(string action, string json)
    {
        using var body = new StringContent(json, Encoding.UTF8, "application/json");
        using var response = await client.PostAsync(url + "/" + action, body);
        var result = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException(result);
        return result;
    }
}
