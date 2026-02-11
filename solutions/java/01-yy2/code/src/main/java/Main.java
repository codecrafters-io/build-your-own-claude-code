import com.openai.client.OpenAIClient;
import com.openai.client.okhttp.OpenAIOkHttpClient;
import com.openai.models.chat.completions.ChatCompletion;
import com.openai.models.chat.completions.ChatCompletionCreateParams;

public class Main {
  public static void main(String[] args) {
    String prompt = getPrompt(args);

    String apiKey = System.getenv("OPENROUTER_API_KEY");
    if (apiKey == null || apiKey.isEmpty()) {
      throw new RuntimeException("OPENROUTER_API_KEY is not set");
    }

    String baseUrl = System.getenv("OPENROUTER_BASE_URL");
    if (baseUrl == null || baseUrl.isEmpty()) {
      baseUrl = "https://openrouter.ai/api/v1";
    }

    OpenAIClient client = OpenAIOkHttpClient.builder().apiKey(apiKey).baseUrl(baseUrl).build();

    ChatCompletion response = client.chat().completions().create(
        ChatCompletionCreateParams.builder()
            .model("anthropic/claude-haiku-4.5")
            .addUserMessage(prompt)
            .build()
    );

    if (response.choices().isEmpty()) {
      throw new RuntimeException("no choices in response");
    }

    System.out.print(response.choices().get(0).message().content().orElse(""));
  }

  private static String getPrompt(String[] args) {
    if (args.length != 2 || !"-p".equals(args[0]) || args[1].isBlank()) {
      throw new RuntimeException("error: -p flag is required");
    }

    return args[1];
  }
}
