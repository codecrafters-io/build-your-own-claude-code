import OpenAI from "openai";

async function main() {
    const [,, flag, prompt] = process.argv;
    const apiKey = process.env.OPENROUTER_API_KEY;
    const baseURL = process.env.OPENROUTER_BASE_URL;

    if (!apiKey) {
        console.error("error: OPENROUTER_API_KEY environment variable is not set");
        process.exit(1);
    }
    if (!baseURL) {
        console.error("error: OPENROUTER_BASE_URL environment variable is not set");
        process.exit(1);
    }
    if (flag !== "-p" || !prompt) {
        console.error("error: -p flag is required");
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
        console.error("error: no choices in response");
        process.exit(1);
    }

    console.log(response.choices[0].message.content);
}

main().catch(err => {
    console.error(`error: ${err.message}`);
    process.exit(1);
});
