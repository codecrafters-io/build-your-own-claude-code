# Only needed for the LSP extension.
# You can ignore this file until you reach that extension.
"""Course-supplied client for the language server the tester starts."""

import json
import os
import urllib.error
import urllib.request


class LSPClient:
    """Sends your agent's messages to the language server.

    The client doesn't track open documents or versions; that state belongs in
    your agent.

    Example:
        lsp = LSPClient.from_environment()
        if lsp is not None:
            language = lsp.extension_to_language[".py"]  # "python"
            result = lsp.call("request", {"method": "textDocument/definition", "params": params})

    Attributes:
        extension_to_language: Maps file extensions, including the dot, to LSP
            language IDs, such as {".py": "python"}.
    """

    @classmethod
    def from_environment(cls):
        """Connects to the language server the tester configured.

        Returns:
            An LSPClient, or None when no language server is configured.
        """
        if "CODECRAFTERS_LSP_URL" not in os.environ:
            return None
        return cls()

    def __init__(self):
        """Connects and reads the extension-to-language mapping."""
        self.url = os.environ["CODECRAFTERS_LSP_URL"]
        self.extension_to_language = self.call("configuration", {})["extensionToLanguage"]

    def call(self, action, payload):
        """Sends one action to the language server.

        Args:
            action: One of:
                "configuration": payload {}.
                "notify": sends an LSP notification. Payload
                    {"method": ..., "params": {...}}.
                "request": sends an LSP request. Payload
                    {"method": ..., "params": {...}}.
                "notifications": reads the server's notifications after a
                    cursor. Payload {"after": cursor, "timeoutMs": ms}; waits up
                    to ms (0 to 5000) when none are queued yet.
            payload: A dict, as described for each action.

        Returns:
            The decoded JSON response:
                "configuration": {"extensionToLanguage": {".py": "python"}}.
                "notify": None.
                "request": the server's result, which may be None, a dict, or a
                    list.
                "notifications": {"cursor": n, "notifications": [...]}, where
                    each notification has "method" and "params". Pass cursor as
                    "after" next time.

        Raises:
            RuntimeError: The language server returned an error, timed out (5
                seconds for a request), or exited. The message is the
                transport's JSON, such as
                '{"error": "language server exited before responding to textDocument/definition"}'.
        """
        request = urllib.request.Request(
            self.url + "/" + action,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            raise RuntimeError(error.read().decode("utf-8")) from error

    def request(self, method, params):
        """Shortcut for call("request", {"method": method, "params": params})."""
        return self.call("request", {"method": method, "params": params})

    def notify(self, method, params):
        """Shortcut for call("notify", {"method": method, "params": params})."""
        return self.call("notify", {"method": method, "params": params})

    def notifications(self, after=0, timeout_ms=0):
        """Shortcut for call("notifications", {"after": after, "timeoutMs": timeout_ms})."""
        return self.call("notifications", {"after": after, "timeoutMs": timeout_ms})
