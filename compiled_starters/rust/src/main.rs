use async_openai::{Client, config::OpenAIConfig};
use clap::Parser;
use serde_json::{Value, json};
use std::{env, process};

#[derive(Parser)]
#[command(author, version, about)]
struct Args {
    #[arg(short = 'p', long)]
    prompt: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    // CodeCrafters sets OPENROUTER_API_KEY and OPENROUTER_BASE_URL when it runs your tests.
    // To run your program locally, set OPENROUTER_API_KEY to your own OpenRouter key.
    let base_url = env::var("OPENROUTER_BASE_URL")
        .unwrap_or_else(|_| "https://openrouter.ai/api/v1".to_string());

    // Tests set OPENROUTER_MODEL to anthropic/claude-haiku-4.5. Locally, you can set it to any model.
    let model =
        env::var("OPENROUTER_MODEL").unwrap_or_else(|_| "anthropic/claude-haiku-4.5".to_string());

    let api_key = env::var("OPENROUTER_API_KEY").unwrap_or_else(|_| {
        eprintln!(
            "OPENROUTER_API_KEY is not set. Tests set it for you. To run locally, set it to your own OpenRouter key."
        );
        process::exit(1);
    });

    let config = OpenAIConfig::new()
        .with_api_base(base_url)
        .with_api_key(api_key);

    let client = Client::with_config(config);

    #[allow(unused_variables)]
    let response: Value = client
        .chat()
        .create_byot(json!({
            "messages": [
                {
                    "role": "user",
                    "content": args.prompt
                }
            ],
            "model": model,
        }))
        .await?;

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    eprintln!("Logs from your program will appear here!");

    // TODO: Uncomment the lines below to pass the first stage
    // if let Some(content) = response["choices"][0]["message"]["content"].as_str() {
    //     println!("{}", content);
    // }

    Ok(())
}
