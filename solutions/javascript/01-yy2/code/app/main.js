import OpenAI from "openai";

async function main() {
  const [, , flag, prompt] = process.argv;
  if (!process.env.OPENROUTER_API_KEY || !process.env.OPENROUTER_BASE_URL) {
    console.error("error: OPENROUTER_API_KEY or OPENROUTER_BASE_URL not set");
    process.exit(1);
  }
  if (flag !== "-p" || !prompt) {
    console.error("error: -p flag is required");
    process.exit(1);
  }

  const client = new OpenAI({
      apiKey: process.env.OPENROUTER_API_KEY,
      baseURL: process.env.OPENROUTER_BASE_URL,
  });
  const response = await client.chat.completions.create({
      model: "anthropic/claude-haiku-4.5",
      messages: [{ role: "user", content: prompt }],
  });
  console.log(response.choices[0]?.message?.content ?? "");
}

main();
