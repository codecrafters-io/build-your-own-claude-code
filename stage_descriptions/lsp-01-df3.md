In this stage, you'll add an LSP tool to your existing agent and follow a call
to its implementation.

### Why give an agent a language server?

The opening replay changes invoice pricing to return `{"cents": 500}` instead of `500`.
Your agent saves a caller that still returns the whole object as an integer.

```text
Write: File saved.
checkout_total(): {"cents": 500}
Expected: 500
```

Write succeeds, but the code has a type error. By the end of this extension,
that Write will return the error so your agent can repair the caller itself.

First, help it find the code to change. Text search finds matching names; a
language server resolves what a symbol refers to. Our invoice project has an
imported alias and an unrelated `preview.total`.

### Connect your existing tool loop

The course starts the configured language server. The supplied client connects
in one line, for example `lsp = LSPClient()` in Python. No server installation,
subprocess code, framing, or handshake is needed. It analyzes Python regardless
of the language you use to implement your agent.

If CODECRAFTERS_LSP_URL is absent, keep your original tools and prompt handling.

Load the supplied `lsp_tool.json` into your request's tools array. When your
existing loop receives this call:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

read the file and send `textDocument/didOpen` once per URI:

```json
{
  "textDocument": {
    "uri": "file:///project/checkout.py",
    "languageId": "python",
    "version": 1,
    "text": "<complete file contents>"
  }
}
```

Use the helper's `notify` action for opening, then its `request` action for
`textDocument/definition`:

```json
{
  "textDocument": { "uri": "file:///project/checkout.py" },
  "position": { "line": 4, "character": 11 }
}
```

Convert absolute paths to encoded file URIs. Tool positions start at one;
protocol positions start at zero and columns count UTF-16 code units.

Return the server's result in the matching model tool result. It can be a
location, an array, or null. Pass protocol errors back as tool errors. The model
can use its existing Read tool to inspect the returned file.

### Tests

The tester asks your agent to resolve `invoice_total` and read its implementation.
It checks document opening, coordinates, result delivery, multiple locations,
null, and errors. The successful lookup points to `pricing.total`, not
`preview.total`.
