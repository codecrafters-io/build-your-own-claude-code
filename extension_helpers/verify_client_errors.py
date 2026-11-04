"""Verify C and Zig preserve helper error bodies and recover on later calls.

Requires Clang with libcurl and cJSON, and Zig 0.17.
"""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import threading


ROOT = Path(__file__).resolve().parents[1]
RESPONSES = [
    (502, {"error": 'language server: {"code":-32603,"message":"Definition unavailable"}',
           "padding": "x" * 8192}),
    (200, {"value": 42}),
    (502, {"error": "A different server error"}),
    (200, None),
]


class ErrorHandler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        path = self.requestline.split()[1]
        if path == "/configuration" and body == {}:
            status, result = 200, {"extensionToLanguage": {".py": "python"}}
        elif path == "/request":
            status, result = RESPONSES[body["case"]]
        else:
            self.send_error(404)
            return
        data = json.dumps(result).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


# Error details must survive failed calls without leaking into later successes.
def verify_error_recovery(name, command, environment):
    # Arrange
    expected = [body for _, body in RESPONSES]

    # Act
    result = subprocess.run(
        command, env=environment, capture_output=True, text=True, timeout=60
    )

    # Assert
    assert result.returncode == 0, (name, result.stderr)
    actual = [json.loads(line) for line in result.stdout.splitlines()]
    assert actual == expected, (name, actual)
    print(f"{name}: error details and recovery passed", flush=True)


def main():
    server = ThreadingHTTPServer(("127.0.0.1", 0), ErrorHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    environment = os.environ.copy()
    environment["CODECRAFTERS_LSP_URL"] = f"http://127.0.0.1:{server.server_port}"
    try:
        with tempfile.TemporaryDirectory(prefix="lsp-client-errors-") as folder:
            directory = Path(folder)
            header = ROOT / "starter_templates/c/code/src/lsp_client.h"
            assert header.read_bytes() == (ROOT / "compiled_starters/c/src/lsp_client.h").read_bytes()
            (directory / "main.c").write_text(f'#include "{header}"\n' + '''int main(void) {
    curl_global_init(CURL_GLOBAL_DEFAULT);
    LSPClient lsp;
    if (!lsp_init(&lsp)) return 1;
    for (int i = 0; i < 4; i++) {
        char payload[32];
        snprintf(payload, sizeof(payload), "{\\"case\\":%d}", i);
        char *result = lsp_call("request", payload);
        const char *response = result ? result : lsp_last_error();
        if (!response || (result && lsp_last_error())) return 1;
        puts(response);
        free(result);
    }
    lsp_deinit(&lsp);
    curl_global_cleanup();
    return 0;
}
''')
            subprocess.run([
                "clang", *shlex.split(environment.get("CFLAGS", "")),
                str(directory / "main.c"), *shlex.split(environment.get("LDFLAGS", "")),
                "-lcurl", "-lcjson", "-o", str(directory / "c-client")
            ], check=True, capture_output=True)
            verify_error_recovery("C", [str(directory / "c-client")], environment)

            client = ROOT / "starter_templates/zig/code/src/lsp_client.zig"
            assert client.read_bytes() == (ROOT / "compiled_starters/zig/src/lsp_client.zig").read_bytes()
            shutil.copyfile(client, directory / "lsp_client.zig")
            (directory / "main.zig").write_text('''const std = @import("std");
const LSPClient = @import("lsp_client.zig").LSPClient;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var lsp = try LSPClient.init(allocator, init.io, init.environ_map.get("CODECRAFTERS_LSP_URL"));
    defer lsp.deinit();
    const payloads = [_][]const u8{
        "{\\"case\\":0}", "{\\"case\\":1}", "{\\"case\\":2}", "{\\"case\\":3}",
    };
    for (payloads) |payload| {
        const result = lsp.call("request", payload) catch |err| {
            const message = lsp.lastError() orelse return err;
            try std.Io.File.stdout().writeStreamingAll(init.io, message);
            try std.Io.File.stdout().writeStreamingAll(init.io, "\\n");
            continue;
        };
        defer allocator.free(result);
        if (lsp.lastError() != null) return error.StaleError;
        try std.Io.File.stdout().writeStreamingAll(init.io, result);
        try std.Io.File.stdout().writeStreamingAll(init.io, "\\n");
    }
}
''')
            executable = directory / "zig-client"
            subprocess.run([
                "zig", "build-exe", str(directory / "main.zig"), f"-femit-bin={executable}"
            ], check=True, timeout=180)
            verify_error_recovery("Zig", [str(executable)], environment)
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == "__main__":
    main()
