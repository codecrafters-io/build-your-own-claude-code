import OpenAI from "openai";

async function main() {
  if (!process.env.OPENROUTER_API_KEY || !process.env.OPENROUTER_BASE_URL) {
    console.error("error: OPENROUTER_API_KEY or OPENROUTER_BASE_URL not set");
    process.exit(1);
  }

  if (process.argv[2] !== "-p" || !process.argv[3]) {
    console.error("error: -p flag is required");
    process.exit(1);
  }

  const client = new OpenAI({
      apiKey: process.env.OPENROUTER_API_KEY,
      baseURL: process.env.OPENROUTER_BASE_URL,
  });
  try {
      const response = await client.chat.completions.create({
          model: "anthropic/claude-haiku-4.5",
          messages: [{ role: "user", content: process.argv[3] }],
      });
      if (!response.choices || response.choices.length === 0) {
          console.error("error: no choices in response");
          process.exit(1);
      }
      const content = response.choices[0]?.message?.content;
      if (!content) {
          console.error("error: empty content in response");
          process.exit(1);
      }
      process.stdout.write(content);
  } catch (error) {
      console.error(error);
      process.exit(1);
  }
}

main();
