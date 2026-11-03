"""Round-trip seven native clients through a local HTTP transport endpoint.

Requires Python, Node 24+, Go 1.25+, a JDK, Clang with libcurl, and Cargo.
C++, C# and Zig clients require their respective build environments.
"""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading


ROOT = Path(__file__).resolve().parents[1]


class EchoHandler(BaseHTTPRequestHandler):
    request_path = "/session/request"

    def log_message(self, *args):
        pass

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        # BaseHTTPRequestHandler normalizes leading double slashes in self.path.
        if self.requestline.split()[1] != self.request_path or body != {
            "method": "test/echo", "params": {"value": 42}
        }:
            self.send_error(400, "Unexpected request")
            return
        result = json.dumps({"value": 42, "padding": "x" * 8192}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(result)))
        self.end_headers()
        self.wfile.write(result)


# Every client must preserve the request and receive the complete large response.
def verify_client(name, command, environment):
    # Arrange
    expected_length = 8192

    # Act
    process = subprocess.run(
        command, env=environment, capture_output=True, text=True, timeout=60
    )

    # Assert
    if process.returncode:
        raise RuntimeError(f"{name}: {process.stderr}")
    result = json.loads(process.stdout)
    assert result["value"] == 42, (name, result)
    assert len(result["padding"]) == expected_length, name
    print(f"{name}: round-trip passed", flush=True)


# Rust clients must route requests with and without a base path.
def verify_rust_client():
    # Arrange
    with tempfile.TemporaryDirectory(prefix="lsp-rust-client-") as folder:
        directory = Path(folder)
        source = ROOT / "starter_templates/rust/code/src/lsp_client.rs"
        compiled = ROOT / "compiled_starters/rust/src/lsp_client.rs"
        assert source.read_bytes() == compiled.read_bytes(), "Rust client copies differ"
        shutil.copyfile(source, directory / "lsp_client.rs")
        (directory / "Cargo.toml").write_text('''[package]
name = "lsp-client-check"
version = "0.1.0"
edition = "2024"

[dependencies]
serde_json = "1.0.149"

[[bin]]
name = "lsp-client-check"
path = "main.rs"
''')
        (directory / "main.rs").write_text('''mod lsp_client;
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = lsp_client::LspClient::new()?;
    let result = client.call("request", &serde_json::json!({
        "method": "test/echo", "params": {"value": 42}
    }))?;
    println!("{result}");
    Ok(())
}
''')
        subprocess.run(
            ["cargo", "build", "--quiet", "--manifest-path", str(directory / "Cargo.toml")],
            check=True, timeout=180,
        )
        command = [str(directory / "target/debug/lsp-client-check")]
        for suffix, expected_path in [
            ("", "/request"),
            ("/", "/request"),
            ("/session", "/session/request"),
            ("/session/nested", "/session/nested/request"),
        ]:
            class Handler(EchoHandler):
                request_path = expected_path

            server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            environment = os.environ.copy()
            environment["CODECRAFTERS_LSP_URL"] = (
                f"http://127.0.0.1:{server.server_port}{suffix}"
            )
            try:
                # Act and Assert
                verify_client(f"Rust URL suffix {suffix!r}", command, environment)
            finally:
                server.shutdown()
                server.server_close()
                thread.join()


def main():
    verify_rust_client()
    server = ThreadingHTTPServer(("127.0.0.1", 0), EchoHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    environment = os.environ.copy()
    environment["CODECRAFTERS_LSP_URL"] = (
        f"http://127.0.0.1:{server.server_port}/session"
    )
    try:
        python_client = str(ROOT / "starter_templates/python/code/app")
        verify_client("Python", ["python3", "-c", (
            f"import sys,json; sys.path.insert(0,{python_client!r}); "
            "from lsp_client import LSPClient; "
            'print(json.dumps(LSPClient().request("test/echo", {"value":42})))'
        )], environment)

        for name, language, extension in [
            ("JavaScript", "javascript", "js"),
            ("TypeScript", "typescript", "ts"),
        ]:
            module = ROOT / f"starter_templates/{language}/code/app/lsp_client.{extension}"
            verify_client(name, ["node", "--input-type=module", "-e", (
                f"import {{LSPClient}} from {json.dumps(module.as_uri())}; "
                'console.log(JSON.stringify(await new LSPClient().request("test/echo", {value:42})));'
            )], environment)

        with tempfile.TemporaryDirectory(prefix="lsp-clients-") as folder:
            directory = Path(folder)
            shutil.copyfile(
                ROOT / "starter_templates/go/code/app/lsp_client.go",
                directory / "lsp_client.go",
            )
            (directory / "main.go").write_text('''package main
import "fmt"
func main() {
    client, err := NewLSPClient()
    if err != nil { panic(err) }
    result, err := client.Call("request", map[string]any{
        "method": "test/echo", "params": map[string]int{"value": 42},
    })
    if err != nil { panic(err) }
    fmt.Println(string(result))
}
''')
            verify_client("Go", [
                "go", "run", str(directory / "main.go"), str(directory / "lsp_client.go")
            ], environment)

            header = ROOT / "starter_templates/c/code/src/lsp_client.h"
            (directory / "main.c").write_text(f'#include "{header}"\n' + '''int main(void) {
    curl_global_init(CURL_GLOBAL_DEFAULT);
    char *result = lsp_call("request", "{\\"method\\":\\"test/echo\\",\\"params\\":{\\"value\\":42}}");
    if (!result) return 1;
    puts(result);
    free(result);
    curl_global_cleanup();
    return 0;
}
''')
            subprocess.run([
                "clang", str(directory / "main.c"), "-lcurl", "-o", str(directory / "c-client")
            ], check=True, capture_output=True)
            verify_client("C", [str(directory / "c-client")], environment)

            shutil.copyfile(
                ROOT / "starter_templates/java/code/src/main/java/LSPClient.java",
                directory / "LSPClient.java",
            )
            (directory / "Main.java").write_text('''class Main {
    public static void main(String[] args) throws Exception {
        System.out.println(new LSPClient().call("request", "{\\"method\\":\\"test/echo\\",\\"params\\":{\\"value\\":42}}"));
    }
}
''')
            subprocess.run([
                "javac", "-d", folder, str(directory / "LSPClient.java"), str(directory / "Main.java")
            ], check=True, capture_output=True)
            verify_client("Java", ["java", "-cp", folder, "Main"], environment)
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == "__main__":
    main()
