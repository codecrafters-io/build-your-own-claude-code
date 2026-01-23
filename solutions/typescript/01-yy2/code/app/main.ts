import OpenAI from "openai";

async function main() {
    const [,, flag, prompt] = process.argv;
    const apiKey = process.env.OPENROUTER_API_KEY;
    const baseURL = process.env.OPENROUTER_BASE_URL;

    if (!apiKey) {
        throw new Error("OPENROUTER_API_KEY is not set")
    }
    if (!baseURL) {
        throw new Error("OPENROUTER_BASE_URL is not set")
    }
    if (flag !== "-p" || !prompt) {
        throw new Error("error: -p flag is required");
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

    console.log(response.choices[0].message.content);
}

main();
