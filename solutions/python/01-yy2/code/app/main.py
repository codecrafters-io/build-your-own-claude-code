import argparse, os, sys
from openai import OpenAI

def main():
    p = argparse.ArgumentParser()
    p.add_argument("-p", required=True)
    args = p.parse_args()

    api_key = os.getenv("OPENROUTER_API_KEY")
    base_url = os.getenv("OPENROUTER_BASE_URL")

    if not api_key:
        print("error: OPENROUTER_API_KEY is not set", file=sys.stderr)
        sys.exit(1)

    if not base_url:
        print("error: OPENROUTER_BASE_URL is not set", file=sys.stderr)
        sys.exit(1)

    client = OpenAI(api_key=api_key, base_url=base_url)
    chat = client.chat.completions.create(
        model="anthropic/claude-haiku-4.5",
        messages=[{"role": "user", "content": args.p}],
    )
    if not chat.choices or len(chat.choices) == 0:
        raise RuntimeError("no choices in response")
    print(chat.choices[0].message.content, end="")

if __name__ == "__main__":
    main()
