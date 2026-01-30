import argparse, os, sys
from openai import OpenAI

def main():
    p = argparse.ArgumentParser()
    p.add_argument("-p", required=True)
    args = p.parse_args()

    api_key = os.getenv("OPENROUTER_API_KEY")
    base_url = os.getenv("OPENROUTER_BASE_URL")

    if not api_key:
        raise RuntimeError("OPENROUTER_API_KEY is not set")

    if not base_url:
        raise RuntimeError("OPENROUTER_BASE_URL is not set")

    client = OpenAI(api_key=api_key, base_url=base_url)

    chat = client.chat.completions.create(
        model="anthropic/claude-haiku-4.5",
        messages=[{"role": "user", "content": args.p}],
        tools=[{
            "type": "function",
            "function": {
                "name": "Read",
                "description": "Read and return the contents of a file",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "file_path": {
                            "type": "string",
                            "description": "The path to the file to read"
                        }
                    },
                    "required": ["file_path"]
                }
            }
        }]
    )

    if not chat.choices:
        raise RuntimeError("no choices in response")

    print(chat.choices[0].message.content)

if __name__ == "__main__":
    main()
