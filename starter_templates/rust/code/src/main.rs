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
    // You can use print statements as follows for debugging, they'll be visible when running tests.
    eprintln!("Logs from your program will appear here!");
    
    let args = Args::parse();
    
    let base_url = env::var("OPENROUTER_BASE_URL").unwrap_or_else(|_| {
        eprintln!("Missing OPENROUTER_BASE_URL");
        process::exit(1);
    });
    
    let api_key = env::var("OPENROUTER_API_KEY").unwrap_or_else(|_| {
        eprintln!("Missing OPENROUTER_API_KEY");
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
    
    // TODO: Uncomment the lines below to pass the first stage
    // if let Some(content) = response["choices"][0]["message"]["content"].as_str() {
    //     println!("{}", content);
    // }
    
    Ok(())
}