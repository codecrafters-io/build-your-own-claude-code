using OpenAI;
using OpenAI.Chat;
using System.ClientModel;

var prompt = "";

for (int i = 0; i < args.Length; i++)
{
    if (args[i] == "-p" && i + 1 < args.Length)
    {
        prompt = args[i + 1];
        break;
    }
}

if (string.IsNullOrEmpty(prompt))
{
    throw new Exception("Prompt must not be empty");
}

var apiKey = Environment.GetEnvironmentVariable("OPENROUTER_API_KEY");
var baseUrl = Environment.GetEnvironmentVariable("OPENROUTER_BASE_URL") ?? "https://openrouter.ai/api/v1";

if (string.IsNullOrEmpty(apiKey))
{
    throw new Exception("OPENROUTER_API_KEY is not set");
}

var client = new ChatClient(
    model: "anthropic/claude-haiku-4.5",
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
