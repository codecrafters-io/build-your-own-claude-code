import OpenAI from "openai";

async function main() {
    // Get the prompt from the -p flag
    const args = process.argv;
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
    const apiKey = process.env.OPENROUTER_API_KEY;
    if (!apiKey) {
        console.error("error: OPENROUTER_API_KEY environment variable is not set");
        process.exit(1);
    }

    const baseURL = process.env.OPENROUTER_BASE_URL;
    if (!baseURL) {
        console.error("error: OPENROUTER_BASE_URL environment variable is not set");
        process.exit(1);
    }

    // Create OpenAI client configured for OpenRouter
    const client = new OpenAI({
        apiKey: apiKey,
        baseURL: baseURL,
    });

    // Make the API request
    let chatCompletion;
    try {
        chatCompletion = await client.chat.completions.create({
            model: "anthropic/claude-haiku-4.5",
            messages: [
                {
                    role: "user",
                    content: prompt,
                },
            ],
        });
    } catch (error) {
        console.error(`error: ${error}`);
        process.exit(1);
    }

    // Check if we got a response
    if (!chatCompletion.choices || chatCompletion.choices.length === 0) {
        console.error("error: no choices in response");
        process.exit(1);
    }

    // Print the response content
    const content = chatCompletion.choices[0].message.content;
    if (!content) {
        console.error("error: empty content in response");
        process.exit(1);
    }
    process.stdout.write(content);
}

main();
