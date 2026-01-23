import OpenAI from "openai";

async function main() {
    // You can use print statements as follows for debugging, they'll be visible when running tests.
    console.error("Logs from your program will appear here!");

    const [,, flag, prompt] = process.argv;
    if (!process.env.OPENROUTER_API_KEY || !process.env.OPENROUTER_BASE_URL) {
        console.error("error: OPENROUTER_API_KEY or OPENROUTER_BASE_URL not set");
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

    // TODO: Uncomment the lines below to pass the first stage
    // const client = new OpenAI({
    //     apiKey: process.env.OPENROUTER_API_KEY,
    //     baseURL: process.env.OPENROUTER_BASE_URL,
    // });
    // const response = await client.chat.completions.create({
    //     model: "anthropic/claude-haiku-4.5",
    //     messages: [{ role: "user", content: prompt }],
    // });
    // console.log(response.choices[0]?.message?.content ?? "");
}

main();
