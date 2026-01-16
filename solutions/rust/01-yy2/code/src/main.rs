use std::env;
use std::process;

use async_openai::{
    config::OpenAIConfig,
    types::{
        ChatCompletionRequestMessage, ChatCompletionRequestUserMessageArgs,
        CreateChatCompletionRequestArgs,
    },
    Client,
};

#[tokio::main]
async fn main() {
    let prompt = get_prompt();
    let api_key = get_env("OPENROUTER_API_KEY");
    let base_url = get_env("OPENROUTER_BASE_URL");

    let config = OpenAIConfig::new()
        .with_api_key(api_key)
        .with_api_base(base_url);

    let client = Client::with_config(config);

    match call_llm(&client, &prompt).await {
        Ok(content) => println!("{}", content),
        Err(e) => fatal(&format!("{}", e)),
    }
}

fn get_prompt() -> String {
    let args: Vec<String> = env::args().collect();
    for (i, arg) in args.iter().enumerate() {
        if arg == "-p" && i + 1 < args.len() {
            return args[i + 1].clone();
        }
    }
    fatal("error: -p flag is required");
}

fn get_env(key: &str) -> String {
    env::var(key).unwrap_or_else(|_| {
        fatal(&format!("error: {} environment variable is not set", key));
    })
}

async fn call_llm(
    client: &Client<OpenAIConfig>,
    prompt: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let user_message = ChatCompletionRequestUserMessageArgs::default()
        .content(prompt)
        .build()?;

    let request = CreateChatCompletionRequestArgs::default()
        .model("anthropic/claude-haiku-4.5")
        .messages(vec![ChatCompletionRequestMessage::User(user_message)])
        .build()?;

    let response = client.chat().create(request).await?;

    if response.choices.is_empty() {
        return Err("no choices in response".into());
    }

    let content = response.choices[0]
        .message
        .content
        .as_ref()
        .ok_or("empty content in response")?;

    Ok(content.clone())
}

fn fatal(message: &str) -> ! {
    eprintln!("{}", message);
    process::exit(1);
}
