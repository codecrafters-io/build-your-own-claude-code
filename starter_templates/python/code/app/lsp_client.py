# Only needed for the LSP extension.
# You can ignore this file until you reach that extension.
"""Course-supplied LSP transport client. Document state belongs in your agent."""

import json
import os
import urllib.error
import urllib.request


class LSPClient:
    @classmethod
    def from_environment(cls):
        if "CODECRAFTERS_LSP_URL" not in os.environ:
            return None
        return cls()

    def __init__(self):
        self.url = os.environ["CODECRAFTERS_LSP_URL"]
        self.extension_to_language = self.call("configuration", {})["extensionToLanguage"]

    def call(self, action, payload):
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
        return self.call("request", {"method": method, "params": params})

    def notify(self, method, params):
        return self.call("notify", {"method": method, "params": params})

    def notifications(self, after=0, timeout_ms=0):
        return self.call("notifications", {"after": after, "timeoutMs": timeout_ms})
