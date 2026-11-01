In this stage, you'll send file changes to the language server.

### Getting answers about the latest code

The language server keeps a copy of each file you open with `didOpen`. Your
`Write` tool saves changes to disk, but the server's copy still contains the old
text until you send an update.

For example, suppose your agent changes a function's parameter from `price: int`
to `price: str`, then asks for hover information again. The server can still
report `int` because it hasn't received the edit. The model would then be making
its next decision using outdated information.

In this stage, you'll send the new contents after a successful write, so later
queries describe the code your agent just saved. LSP uses
[`textDocument/didChange`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange)
to send the new text to the server.

### Sending a change

Update your `Write` handler. After successfully writing an open file:

1. Increase that document's version number.
2. Send a `textDocument/didChange` notification containing its complete new
   text.
3. Continue the agent loop only after sending the notification.

```json
{
  "jsonrpc": "2.0",
  "method": "textDocument/didChange",
  "params": {
    "textDocument": {
      "uri": "file:///path/to/project/pricing.py",
      "version": 2
    },
    "contentChanges": [
      {
        "text": "def total(price: str, quantity: int) -> str:\n    return price * quantity\n"
      }
    ]
  }
}
```

The tester's server advertises:

```json
{ "textDocumentSync": { "openClose": true, "change": 1 } }
```

Here, `change: 1` means **full synchronization**. Each change contains the whole
file, so you don't need to calculate a diff. Keep a separate version counter for
each open URI. The first write after `didOpen` changes version `1` to `2`.

If the file hasn't been opened, leave it alone for now. When the model first
queries it, your existing code will send `didOpen` with its current contents. If
a write fails, don't send `didChange`.

### Tests

The tester will create `pricing.py` and run:

```bash
$ ./your_program.sh -p "Hover on pricing.py at line 1, character 5. Use Write to change total to accept price: str and return str. Hover at the same position again."
```

The server must receive the version `2` change shown above before the second
hover. It then returns:

```json
{
  "contents": {
    "kind": "plaintext",
    "value": "(price: str, quantity: int) -> str"
  }
}
```

The tester checks that the model receives the updated signature. It also checks
successive writes, unopened files, failed writes, and reuse of the same server
process.

### Notes

- Keep the server running between queries so it can apply changes to the
  documents you've opened.
- For this extension, synchronize edits made through your file tools. Detecting
  changes made by arbitrary shell commands or other applications is outside the
  exercise.
