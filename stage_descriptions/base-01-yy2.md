Claude Code uses a REST API to communicate with the Large Language Model (LLM). In this stage, you'll communicate with the provided LLM using an [OpenAI-compatible API](https://openrouter.ai/docs/quickstart#using-the-openrouter-api).

### The LLM in tests

When CodeCrafters runs your tests, it sets two environment variables for your program:

- `OPENROUTER_API_KEY`: The API key for the request
- `OPENROUTER_BASE_URL`: The URL to send the request to

The starter code already reads both, so you don't need an OpenRouter account to pass any stage.

Keep these two variable names and the `anthropic/claude-haiku-4.5` model as they are. The tests don't set any other API key (like `OPENAI_API_KEY`), and they reject requests for any other model.

### Running locally

Passing this stage doesn't require running your program locally. From the next stage on, you might want to try a prompt on your own machine before submitting.

Those two variables aren't set on your machine, so a local run fails with `OPENROUTER_API_KEY is not set`. To fix this, create an [OpenRouter API key](https://openrouter.ai/keys) and set it in your terminal:

```bash
$ export OPENROUTER_API_KEY="<your key>"
$ ./your_program.sh -p "What is 2 + 2?"
4
```

You can leave `OPENROUTER_BASE_URL` unset. The starter code falls back to OpenRouter's URL.

Locally, you can switch to any model your key can use. Switch back to `anthropic/claude-haiku-4.5` before you submit.
