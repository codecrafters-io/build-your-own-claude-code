// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied client for the language server the tester starts.
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Sends your agent's messages to the language server.
 *
 * <p>The client doesn't track open documents or versions; that state belongs in
 * your agent. Payloads and responses are JSON text, so build and parse them with
 * your existing JSON library.
 *
 * <pre>{@code
 * var lsp = LSPClient.fromEnvironment();
 * if (lsp != null) {
 *     var language = lsp.extensionToLanguage.get(".py"); // "python"
 *     String result = lsp.call("request", "{\"method\": \"textDocument/definition\", \"params\": {...}}");
 * }
 * }</pre>
 */
public final class LSPClient {
    private final String url;
    private final HttpClient client = HttpClient.newHttpClient();
    /** Maps file extensions, including the dot, to LSP language IDs, such as {@code {".py": "python"}}. */
    public final Map<String, String> extensionToLanguage;

    private record Configuration(Map<String, String> extensionToLanguage) {}

    /**
     * Connects to the language server the tester configured.
     *
     * @return the client, or {@code null} when no language server is configured
     * @throws Exception if connecting or reading the language mapping fails
     */
    public static LSPClient fromEnvironment() throws Exception {
        if (System.getenv("CODECRAFTERS_LSP_URL") == null) return null;
        return new LSPClient();
    }

    /**
     * Connects and reads the extension-to-language mapping.
     *
     * @throws Exception if no language server is configured, or connecting fails
     */
    public LSPClient() throws Exception {
        url = System.getenv("CODECRAFTERS_LSP_URL");
        if (url == null) throw new IllegalStateException("Run with the course LSP transport");
        extensionToLanguage = new ObjectMapper()
            .readValue(call("configuration", "{}"), Configuration.class).extensionToLanguage();
    }

    /**
     * Sends one action to the language server.
     *
     * <p>Actions and their payloads:
     * <ul>
     *   <li>{@code "configuration"}: {@code {}}. Returns
     *       {@code {"extensionToLanguage": {".py": "python"}}}.
     *   <li>{@code "notify"}: {@code {"method": ..., "params": {...}}}, an LSP
     *       notification. Returns {@code null} as JSON text.
     *   <li>{@code "request"}: {@code {"method": ..., "params": {...}}}, an LSP
     *       request. Returns the server's result, which may be {@code null}, an
     *       object, or an array.
     *   <li>{@code "notifications"}: {@code {"after": cursor, "timeoutMs": ms}}.
     *       Returns {@code {"cursor": n, "notifications": [...]}}: the server's
     *       notifications after the cursor, each with {@code method} and
     *       {@code params}. Waits up to {@code ms} (0 to 5000) when none are
     *       queued yet. Pass the returned cursor as {@code after} next time.
     * </ul>
     *
     * @param action {@code "configuration"}, {@code "notify"}, {@code "request"},
     *     or {@code "notifications"}
     * @param json the action's payload as JSON text, as above
     * @return the response as JSON text
     * @throws IllegalStateException if the language server returned an error,
     *     timed out (5 seconds for a request), or exited. The message is the
     *     transport's JSON, such as
     *     {@code {"error":"language server exited before responding to textDocument/definition"}}.
     * @throws Exception if the HTTP call to the transport fails
     */
    public String call(String action, String json) throws Exception {
        var request = HttpRequest.newBuilder(URI.create(url + "/" + action))
            .timeout(Duration.ofSeconds(10))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(json)).build();
        var response = client.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) throw new IllegalStateException(response.body());
        return response.body();
    }
}
