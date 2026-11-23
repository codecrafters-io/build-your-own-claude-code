using OpenAI;
using OpenAI.Chat;
using System.ClientModel;

if (args.Length < 2 || args[0] != "-p")
{
    throw new Exception("Usage: program -p <prompt>");
}

var prompt = args[1];

if (string.IsNullOrEmpty(prompt))
{
    throw new Exception("Prompt must not be empty");
}

// CodeCrafters sets OPENROUTER_API_KEY and OPENROUTER_BASE_URL when it runs your tests.
// To run your program locally, set OPENROUTER_API_KEY to your own OpenRouter key.
var apiKey = Environment.GetEnvironmentVariable("OPENROUTER_API_KEY");
var baseUrl = Environment.GetEnvironmentVariable("OPENROUTER_BASE_URL") ?? "https://openrouter.ai/api/v1";

// CodeCrafters sets OPENROUTER_MODEL to anthropic/claude-haiku-4.5 when it runs your tests. Locally, you can set it to any model.
var model = Environment.GetEnvironmentVariable("OPENROUTER_MODEL") ?? "anthropic/claude-haiku-4.5";

if (string.IsNullOrEmpty(apiKey))
{
    throw new Exception("OPENROUTER_API_KEY is not set. CodeCrafters sets it when you run `codecrafters test` or `codecrafters submit`. To run your program directly, set it to your own OpenRouter key.");
}

var client = new ChatClient(
    model: model,
    credential: new ApiKeyCredential(apiKey),
    options: new OpenAIClientOptions { Endpoint = new Uri(baseUrl) }
);

ChatCompletion response = client.CompleteChat(
    [new UserChatMessage(prompt)]
);

if (response.Content == null || response.Content.Count == 0)
{
    throw new Exception("No choices in response");
}

Console.Write(response.Content[0].Text);
