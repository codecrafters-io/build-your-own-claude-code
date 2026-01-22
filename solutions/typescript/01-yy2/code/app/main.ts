import OpenAI, { ChatCompletionRequestMessage } from "openai";

async function makeChatCompletion(client: OpenAI, prompt: string): Promise<string | null> {
    try {
        const response = await client.chat.completions.create({
            model: "anthropic/claude-haiku-4.5",
            messages: [{ role: "user", content: prompt }] as ChatCompletionRequestMessage[],
        });

        return response.choices?.[0]?.message?.content ?? null;
    } catch (error) {
        console.error(`error: ${error}`);
        process.exit(1);
    }
}

async function main(): Promise<void> {
    // Get the prompt from the -p flag
    const args: string[] = process.argv;
    let prompt: string | undefined;

    for (let i = 0; i < args.length; i++) {
        if (args[i] === "-p" && i + 1 < args.length) {
            prompt = args[i + 1];
            break;
        }
    }

    if (!prompt) {
        console.error("error: -p flag is required");
        process.exit(1);
    }

    // Get API key and base URL from environment variables
    const apiKey: string | undefined = process.env.OPENROUTER_API_KEY;
    const baseURL: string | undefined = process.env.OPENROUTER_BASE_URL;

    if (!apiKey || !baseURL) {
        console.error("error: OPENROUTER_API_KEY or OPENROUTER_BASE_URL not set");
        process.exit(1);
    }

    const client = new OpenAI({ apiKey, baseURL });

    const result: string | null = await makeChatCompletion(client, prompt);
    process.stdout.write(result ?? "");
}

main();
