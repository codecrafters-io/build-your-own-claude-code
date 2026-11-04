// Course-supplied transport; pass JSON using your existing JSON library.
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

public sealed class LSPClient
{
    private readonly string url = Environment.GetEnvironmentVariable("CODECRAFTERS_LSP_URL")
        ?? throw new InvalidOperationException("Run with the course LSP transport");
    private static readonly HttpClient client = new HttpClient { Timeout = TimeSpan.FromSeconds(10) };
    public IReadOnlyDictionary<string, string> ExtensionToLanguage { get; private set; } = null!;

    private LSPClient() {}

    public static async Task<LSPClient?> FromEnvironmentAsync()
    {
        if (Environment.GetEnvironmentVariable("CODECRAFTERS_LSP_URL") == null) return null;
        return await CreateAsync();
    }

    public static async Task<LSPClient> CreateAsync()
    {
        var lsp = new LSPClient();
        var configurationJson = await lsp.Call("configuration", "{}");
        using var configuration = JsonDocument.Parse(configurationJson);
        lsp.ExtensionToLanguage = configuration.RootElement.GetProperty("extensionToLanguage")
            .Deserialize<Dictionary<string, string>>()!;
        return lsp;
    }

    public async Task<string> Call(string action, string json)
    {
        using var body = new StringContent(json, Encoding.UTF8, "application/json");
        using var response = await client.PostAsync(url + "/" + action, body);
        var result = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException(result);
        return result;
    }
}
