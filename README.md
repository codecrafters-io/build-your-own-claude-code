# build-your-own-claude-code

Content for the "Build your own Claude Code" challenge.

## Setup

This challenge is developed using https://github.com/codecrafters-io/course-sdk.
Read its README for language support and submission workflows.

## LSP extension

Five short stages start with connecting the supplied helper and advertising the
LSP tool. Definition lookup, references, document synchronization, and diagnostic
feedback then build on that setup. The helper handles server startup and transport.

- [Extension design](extension_designs/lsp.md)
- [Supplied helper and language clients](extension_helpers/README.md)
- [Invoice API migration and before/after demo](extension_designs/lsp_exercise/README.md)

In the companion claude-code-tester checkout, with Go 1.25.5 and Python 3.10+:

```sh
make test_lsp
make test_lsp_offline
make test_lsp_with_pyright
```

The first two need no model credentials. The third requires an installed
Pyright language server and checks the integration independently of the fixture.
For live-model trials, set CODECRAFTERS_SECRET_OPENROUTER_API_KEY and run
`make test_lsp_with_users_code`. Learner trials and live-model reliability checks
remain release gates.
