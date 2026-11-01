# build-your-own-claude-code

Content for the "Build your own Claude Code" challenge

## Setup

This challenge is developed using https://github.com/codecrafters-io/course-sdk.
Read the README there for information on how to contribute language support &
submit solutions.

## Run the LSP extension locally

The companion `claude-code-tester` checkout contains all seven registered
stages, a controlled stdio language server, and a reference agent. With Go
1.25.5 and Python 3.10 or newer, run these commands in that checkout:

```sh
make test_lsp
make test_lsp_offline
```

The first command checks recorded output, fixture helpers, registration, and
broken-client regressions. The second runs the extension against the reference
agent using a local model that emits tool calls. Neither needs an API key.

For the existing live-model test workflow, configure
`CODECRAFTERS_SECRET_OPENROUTER_API_KEY` and run
`make test_lsp_with_users_code`. See
[the extension design](extension_designs/lsp.md) for protocol scope and
validation status, and
[the invoice exercise](extension_designs/lsp_exercise/README.md) for the sample
task. Live-model trials remain outstanding before publication.
