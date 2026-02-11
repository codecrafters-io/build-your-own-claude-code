import com.openai.client.OpenAIClient;
import com.openai.client.okhttp.OpenAIOkHttpClient;
import com.openai.models.chat.completions.ChatCompletion;
import com.openai.models.chat.completions.ChatCompletionCreateParams;

public class Main {
  public static void main(String[] args) {
    String prompt = parsePrompt(args);
    String apiKey = System.getenv("OPENROUTER_API_KEY");
    String baseUrl = System.getenv("OPENROUTER_BASE_URL");

    if (baseUrl == null || baseUrl.isBlank()) {
      baseUrl = "https://openrouter.ai/api/v1";
    }

    if (apiKey == null || apiKey.isBlank()) {
      throw new RuntimeException("OPENROUTER_API_KEY is not set");
    }

    OpenAIClient client = OpenAIOkHttpClient.builder()
        .apiKey(apiKey)
        .baseUrl(baseUrl)
        .build();

    ChatCompletion response = client.chat().completions().create(
        ChatCompletionCreateParams.builder()
            .model("anthropic/claude-haiku-4.5")
            .addUserMessage(prompt)
            .build());

    if (response.choices().isEmpty()) {
      throw new RuntimeException("no choices in response");
    }

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    System.err.println("Logs from your program will appear here!");

    // TODO: Uncomment the code below to pass the first stage
    // System.out.println(response.choices().get(0).message().content().orElseThrow());
  }

  private static String parsePrompt(String[] args) {
    for (int i = 0; i < args.length - 1; i++) {
      if ("-p".equals(args[i]) && args[i + 1] != null && !args[i + 1].isBlank()) {
        return args[i + 1];
      }
    }

    throw new RuntimeException("error: -p flag is required");
  }
}
