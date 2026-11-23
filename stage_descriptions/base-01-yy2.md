Claude Code uses a REST API to communicate with the Large Language Model (LLM). In this stage, you'll communicate with the provided LLM using an [OpenAI-compatible API](https://openrouter.ai/docs/quickstart#using-the-openrouter-api).

### The LLM in tests

When CodeCrafters runs your tests, it sets three environment variables for your program:

- `OPENROUTER_API_KEY`: The API key for the request
- `OPENROUTER_BASE_URL`: The URL to send the request to
- `OPENROUTER_MODEL`: The model to request (`anthropic/claude-haiku-4.5`)

The starter code already reads all three, so you don't need your own API key to pass any stage. The tests don't set any other API key (like `OPENAI_API_KEY`), and they only accept Claude Haiku models.

### Running locally

Running your program on your own machine is optional. These variables aren't set there, so a local run fails with `OPENROUTER_API_KEY is not set`.

To run locally, create an API key on [OpenRouter](https://openrouter.ai/keys), the service that provides the LLM. Requests made with your own key use your OpenRouter credits, so add credits or pick a free model (their names end in `:free`). Then set the key and a model in your terminal, and pass a prompt with `-p`:

```bash
$ export OPENROUTER_API_KEY="<your key>"
$ export OPENROUTER_MODEL="anthropic/claude-haiku-4.5"
$ ./your_program.sh -p "What is 2 + 2?"
4
```

Locally, `OPENROUTER_MODEL` can be any model on OpenRouter. The tests always use Claude Haiku.
