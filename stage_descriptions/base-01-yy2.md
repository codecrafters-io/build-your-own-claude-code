Claude Code uses a REST API to communicate with the Large Language Model (LLM). In this stage, you'll communicate with the provided LLM using an [OpenAI-compatible API](https://openrouter.ai/docs/quickstart#using-the-openrouter-api).

### The LLM in tests

When CodeCrafters runs your tests, it sets three environment variables for your program:

- `OPENROUTER_API_KEY`: The API key for the request
- `OPENROUTER_BASE_URL`: The URL to send the request to
- `OPENROUTER_MODEL`: The model to request (`anthropic/claude-haiku-4.5`)

The starter code already reads all three, so you don't need an OpenRouter account to pass any stage. The tests don't set any other API key (like `OPENAI_API_KEY`), and they reject requests for any other model.

### Running locally

These variables aren't set on your machine, so a local run fails with `OPENROUTER_API_KEY is not set`. To run your program locally, create an [OpenRouter API key](https://openrouter.ai/keys), then set the key and a model in your terminal:

```bash
$ export OPENROUTER_API_KEY="<your key>"
$ export OPENROUTER_MODEL="anthropic/claude-haiku-4.5"
$ ./your_program.sh -p "What is 2 + 2?"
4
```

Locally, you can set `OPENROUTER_MODEL` to any model your key can use.
