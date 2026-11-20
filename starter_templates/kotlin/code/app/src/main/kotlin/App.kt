import com.openai.client.okhttp.OpenAIOkHttpClient
import com.openai.models.ChatModel
import com.openai.models.chat.completions.ChatCompletionCreateParams

fun main(args: Array<String>) {
    var prompt = ""
    var i = 0
    while (i < args.size) {
        if (args[i] == "-p" && i + 1 < args.size) {
            prompt = args[i + 1]
            i += 2
        } else {
            i++
        }
    }

    if (prompt.isEmpty()) {
        throw RuntimeException("Prompt must not be empty")
    }

    val apiKey = System.getenv("OPENROUTER_API_KEY")
        ?: throw RuntimeException("OPENROUTER_API_KEY is not set")
    val baseUrl = System.getenv("OPENROUTER_BASE_URL") ?: "https://openrouter.ai/api/v1"

    val client = OpenAIOkHttpClient.builder()
        .apiKey(apiKey)
        .baseUrl(baseUrl)
        .build()

    val response = client.chat().completions().create(
        ChatCompletionCreateParams.builder()
            .model(ChatModel.of("anthropic/claude-haiku-4.5"))
            .addUserMessage(prompt)
            .build()
    )

    if (response.choices().isEmpty()) {
        throw RuntimeException("no choices in response")
    }

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    System.err.println("Logs from your program will appear here!")

    // TODO: Uncomment the following line to pass the first stage
    // print(response.choices()[0].message().content().get())
}
