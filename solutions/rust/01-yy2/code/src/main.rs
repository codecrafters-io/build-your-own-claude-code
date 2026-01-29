use async_openai::{Client, config::OpenAIConfig};
use clap::Parser;
use serde_json::{json, Value};
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
    
    let base_url = env::var("OPENROUTER_BASE_URL").unwrap_or_else(|_| {
        eprintln!("OPENROUTER_BASE_URL is not set");
        process::exit(1);
    });
    
    let api_key = env::var("OPENROUTER_API_KEY").unwrap_or_else(|_| {
        eprintln!("OPENROUTER_API_KEY is not set");
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
            "model": "anthropic/claude-haiku-4.5"
        }))
        .await?;
    
    if let Some(content) = response["choices"][0]["message"]["content"].as_str() {
        println!("{}", content);
    }
    
    Ok(())
}