use async_openai::{
    Client,
    config::OpenAIConfig,
    types::{ChatCompletionRequestUserMessageArgs, CreateChatCompletionRequestArgs},
};
use std::{env, error::Error, process};

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();

    // Parse 'prompt' argument
    let prompt = if args.len() > 2 && args[1] == "-p" {
        args[2].clone()
    } else {
        println!("Expected usage: -p \"Your prompt\"");
        process::exit(1);
    };

    let api_key = env::var("OPENROUTER_API_KEY").map_err(|_| "OPENROUTER_API_KEY not set")?;
    let base_url = env::var("OPENROUTER_BASE_URL").map_err(|_| "OPENROUTER_BASE_URL not set")?;

    let config = OpenAIConfig::new()
        .with_api_key(api_key)
        .with_api_base(base_url);

    let client = Client::with_config(config);

    let request = CreateChatCompletionRequestArgs::default()
        .model("anthropic/claude-haiku-4.5")
        .messages([ChatCompletionRequestUserMessageArgs::default()
            .content(prompt)
            .build()?
            .into()])
        .build()?;

    let response = client.chat().create(request).await?;

    // This is to force compilation without using this variable
    // Feel free to remove this line
    let _ = response;

    if let Some(choice) = response.choices.first() {
        println!("{}", choice.message.content.as_deref().unwrap_or_default());
    }

    Ok(())
}
