import argparse
import os
import sys

from openai import OpenAI

def main():
    # Get the prompt from the -p flag
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", required=True, help="Prompt to send to LLM")
    args = parser.parse_args()

    # Get API key and base URL from environment variables
    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        print("error: OPENROUTER_API_KEY environment variable is not set", file=sys.stderr)
        sys.exit(1)

    base_url = os.getenv("OPENROUTER_BASE_URL")
    if not base_url:
        print("error: OPENROUTER_BASE_URL environment variable is not set", file=sys.stderr)
        sys.exit(1)

    # Create OpenAI client configured for OpenRouter
    client = OpenAI(
        api_key=api_key,
        base_url=base_url,
    )

    # Make the API request
    chat_completion = client.chat.completions.create(
        model="openai/gpt-4o-mini",
        messages=[
            {"role": "user", "content": args.p}
        ]
    )

    # Check if we got a response
    if len(chat_completion.choices) == 0:
        print("error: no choices in response", file=sys.stderr)
        sys.exit(1)
    
    # # Print the response content
    # content = chat_completion.choices[0].message.content
    # if not content:
    #     print("error: empty content in response", file=sys.stderr)
    #     sys.exit(1)
    
    # print(content, end="")


if __name__ == "__main__":
    main()
