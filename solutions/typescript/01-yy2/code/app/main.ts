import OpenAI from "openai";

async function main() {
    const [,, flag, prompt] = process.argv;
    const apiKey = process.env.OPENROUTER_API_KEY;
    const baseURL = process.env.OPENROUTER_BASE_URL;

    if (!apiKey) {
        console.error("error: OPENROUTER_API_KEY not set");
        process.exit(1);
    }
    if (!baseURL) {
        console.error("error: OPENROUTER_BASE_URL not set");
        process.exit(1);
    }
    if (flag !== "-p") {
        console.error("error: -p flag is required");
        process.exit(1);
    }
    if (!prompt) {
        console.error("error: prompt value is required");
        process.exit(1);
    }

    const client = new OpenAI({
        apiKey: apiKey,
        baseURL: baseURL,
    });
    const response = await client.chat.completions.create({
        model: "anthropic/claude-haiku-4.5",
        messages: [{ role: "user", content: prompt }],
    });
    if (!response.choices || response.choices.length === 0) {
        throw new Error("no choices in response");
    }
    const content = response.choices[0].message.content;
    if (!content) {
        console.error("error: empty content in response");
        process.exit(1);
    }
    process.stdout.write(content);
}

main().catch((error) => {
    console.error(error.message);
    process.exit(1);
});
