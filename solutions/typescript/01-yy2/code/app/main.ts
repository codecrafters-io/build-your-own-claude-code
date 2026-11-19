import OpenAI from "openai";

async function main() {
  const [, , flag, prompt] = process.argv;
  // CodeCrafters sets OPENROUTER_API_KEY and OPENROUTER_BASE_URL when it runs your tests.
  // To run your program locally, set OPENROUTER_API_KEY to your own OpenRouter key.
  const apiKey = process.env.OPENROUTER_API_KEY;
  const baseURL =
    process.env.OPENROUTER_BASE_URL ?? "https://openrouter.ai/api/v1";
  // Tests set OPENROUTER_MODEL to anthropic/claude-haiku-4.5. Locally, you can set it to any model.
  const model = process.env.OPENROUTER_MODEL ?? "anthropic/claude-haiku-4.5";

  if (!apiKey) {
    throw new Error(
      "OPENROUTER_API_KEY is not set. Tests set it for you. To run locally, set it to your own OpenRouter key.",
    );
  }
  if (flag !== "-p" || !prompt) {
    throw new Error("error: -p flag is required");
  }

  const client = new OpenAI({
    apiKey: apiKey,
    baseURL: baseURL,
  });

  const response = await client.chat.completions.create({
    model: model,
    messages: [{ role: "user", content: prompt }],
  });

  if (!response.choices || response.choices.length === 0) {
    throw new Error("no choices in response");
  }

  console.log(response.choices[0].message.content);
}

main();
