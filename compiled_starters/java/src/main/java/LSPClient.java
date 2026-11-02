// Course-supplied transport; pass JSON using your existing JSON library.
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public final class LSPClient {
    private final String url;
    private final HttpClient client = HttpClient.newHttpClient();

    public LSPClient() {
        url = System.getenv("CODECRAFTERS_LSP_URL");
        if (url == null) throw new IllegalStateException("Run with the course LSP transport");
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
