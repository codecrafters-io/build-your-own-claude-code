// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied transport; pass JSON using your existing JSON library.
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;
import com.fasterxml.jackson.databind.ObjectMapper;

public final class LSPClient {
    private final String url;
    private final HttpClient client = HttpClient.newHttpClient();
    public final Map<String, String> extensionToLanguage;

    private record Configuration(Map<String, String> extensionToLanguage) {}

    public static LSPClient fromEnvironment() throws Exception {
        if (System.getenv("CODECRAFTERS_LSP_URL") == null) return null;
        return new LSPClient();
    }

    public LSPClient() throws Exception {
        url = System.getenv("CODECRAFTERS_LSP_URL");
        if (url == null) throw new IllegalStateException("Run with the course LSP transport");
        extensionToLanguage = new ObjectMapper()
            .readValue(call("configuration", "{}"), Configuration.class).extensionToLanguage();
    }

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
