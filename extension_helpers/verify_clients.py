"""Initialize and round-trip nine native clients through a local HTTP endpoint.

Requires Python, Node 24+, Go 1.25+, a JDK with Jackson, Clang with libcurl and
cJSON, Cargo, .NET 10 and Zig 0.17. Set CLASSPATH for Jackson outside /usr/share/java.
The C++ client requires its CPR build environment.
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
LANGUAGES = {".ts": "typescript", ".tsx": "typescript"}


class EchoHandler(BaseHTTPRequestHandler):
    request_path = "/session/request"

    def log_message(self, *args):
        pass

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        path = self.requestline.split()[1]
        self.server.calls.append((path, body))
        # BaseHTTPRequestHandler normalizes leading double slashes in self.path.
        if path == self.request_path.removesuffix("request") + "configuration" and body == {}:
            status = 502 if self.server.configuration_error else 200
            result = {"error": "Configuration unavailable"} if status == 502 else {
                "extensionToLanguage": LANGUAGES
            }
        elif path == self.request_path and body == {
            "method": "test/echo", "params": {"value": 42}
        }:
            status = 200
            result = {"value": 42, "padding": "x" * 8192}
        else:
            self.send_error(400, "Unexpected request")
            return
        result = json.dumps(result).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(result)))
        self.end_headers()
        self.wfile.write(result)


# Initialization must expose the configured mapping after fetching it once.
def verify_initialization(name, mapping, calls, request_path):
    # Arrange
    configuration_path = request_path.removesuffix("request") + "configuration"

    # Act
    configuration_calls = [call for call in calls if call[0] == configuration_path]

    # Assert
    assert mapping == LANGUAGES, (name, mapping)
    assert configuration_calls == [(configuration_path, {})], (name, calls)
    assert calls[0] == (configuration_path, {}), (name, calls)
    print(f"{name}: initialization passed", flush=True)


# A failed configuration fetch must stop initialization before any tool request.
def verify_initialization_failure(name, command, environment, server):
    # Arrange
    server.calls.clear()
    server.configuration_error = True

    # Act
    try:
        process = subprocess.run(
            command, env=environment, capture_output=True, text=True, timeout=60
        )
    finally:
        server.configuration_error = False

    # Assert
    assert process.returncode != 0, (name, process.stdout)
    assert len(server.calls) == 1 and server.calls[0][0].endswith("/configuration"), (
        name, server.calls
    )
    print(f"{name}: initialization failure passed", flush=True)


# Every initialized client must still receive the complete large tool response.
def verify_client(name, command, environment, server):
    # Arrange
    expected_length = 8192
    server.calls = []
    server.configuration_error = False

    # Act
    process = subprocess.run(
        command, env=environment, capture_output=True, text=True, timeout=60
    )

    # Assert
    if process.returncode:
        raise RuntimeError(f"{name}: {process.stderr}")
    mapping, result = [json.loads(line) for line in process.stdout.splitlines()]
    verify_initialization(name, mapping, server.calls, server.RequestHandlerClass.request_path)
    assert result["value"] == 42, (name, result)
    assert len(result["padding"]) == expected_length, name
    print(f"{name}: round-trip passed", flush=True)
    verify_initialization_failure(name, command, environment, server)


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
    println!("{}", serde_json::to_string(&client.extension_to_language)?);
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
                verify_client(f"Rust URL suffix {suffix!r}", command, environment, server)
            finally:
                server.shutdown()
                server.server_close()
                thread.join()


def verify_csharp_client(directory, environment, server):
    shutil.copyfile(
        ROOT / "starter_templates/csharp/code/src/LSPClient.cs",
        directory / "LSPClient.cs",
    )
    (directory / "ClientCheck.csproj").write_text('''<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
''')
    (directory / "Program.cs").write_text('''using System;
using System.Text.Json;
var lsp = await LSPClient.CreateAsync();
Console.WriteLine(JsonSerializer.Serialize(lsp.ExtensionToLanguage));
Console.WriteLine(await lsp.Call("request", "{\\"method\\":\\"test/echo\\",\\"params\\":{\\"value\\":42}}"));
''')
    subprocess.run([
        "dotnet", "build", str(directory / "ClientCheck.csproj"), "--output", str(directory / "dotnet")
    ], check=True, capture_output=True, timeout=180, env=environment)
    verify_client("C#", ["dotnet", str(directory / "dotnet/ClientCheck.dll")], environment, server)


def verify_zig_client(directory, environment, server):
    shutil.copyfile(
        ROOT / "starter_templates/zig/code/src/lsp_client.zig",
        directory / "lsp_client.zig",
    )
    (directory / "main.zig").write_text('''const std = @import("std");
const LSPClient = @import("lsp_client.zig").LSPClient;
pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var lsp = try LSPClient.init(allocator, init.io, init.environ_map.get("CODECRAFTERS_LSP_URL"));
    defer lsp.deinit();
    const mapping = try std.json.Stringify.valueAlloc(allocator, std.json.Value{ .object = lsp.extension_to_language }, .{});
    defer allocator.free(mapping);
    try std.Io.File.stdout().writeStreamingAll(init.io, mapping);
    try std.Io.File.stdout().writeStreamingAll(init.io, "\\n");
    const result = try lsp.call("request", "{\\"method\\":\\"test/echo\\",\\"params\\":{\\"value\\":42}}");
    defer allocator.free(result);
    try std.Io.File.stdout().writeStreamingAll(init.io, result);
    try std.Io.File.stdout().writeStreamingAll(init.io, "\\n");
}
''')
    executable = directory / "zig-client"
    subprocess.run([
        "zig", "build-exe", str(directory / "main.zig"), f"-femit-bin={executable}"
    ], check=True, timeout=180, env=environment)
    verify_client("Zig", [str(executable)], environment, server)


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
            'lsp = LSPClient(); print(json.dumps(lsp.extension_to_language)); '
            'print(json.dumps(lsp.request("test/echo", {"value":42})))'
        )], environment, server)

        for name, language, extension in [
            ("JavaScript", "javascript", "js"),
            ("TypeScript", "typescript", "ts"),
        ]:
            module = ROOT / f"starter_templates/{language}/code/app/lsp_client.{extension}"
            verify_client(name, ["node", "--input-type=module", "-e", (
                f"import {{LSPClient}} from {json.dumps(module.as_uri())}; "
                'const lsp = await LSPClient.create(); '
                'console.log(JSON.stringify(lsp.extensionToLanguage)); '
                'console.log(JSON.stringify(await lsp.request("test/echo", {value:42})));'
            )], environment, server)

        with tempfile.TemporaryDirectory(prefix="lsp-clients-") as folder:
            directory = Path(folder)
            shutil.copyfile(
                ROOT / "starter_templates/go/code/app/lsp_client.go",
                directory / "lsp_client.go",
            )
            (directory / "main.go").write_text('''package main
import ("fmt"; "encoding/json")
func main() {
    client, err := NewLSPClient()
    if err != nil { panic(err) }
    mapping, err := json.Marshal(client.ExtensionToLanguage)
    if err != nil { panic(err) }
    fmt.Println(string(mapping))
    result, err := client.Call("request", map[string]any{
        "method": "test/echo", "params": map[string]int{"value": 42},
    })
    if err != nil { panic(err) }
    fmt.Println(string(result))
}
''')
            verify_client("Go", [
                "go", "run", str(directory / "main.go"), str(directory / "lsp_client.go")
            ], environment, server)

            header = ROOT / "starter_templates/c/code/src/lsp_client.h"
            (directory / "main.c").write_text(f'#include "{header}"\n' + '''int main(void) {
    curl_global_init(CURL_GLOBAL_DEFAULT);
    LSPClient lsp;
    if (!lsp_init(&lsp)) return 1;
    char *mapping = cJSON_PrintUnformatted(lsp.extension_to_language);
    puts(mapping);
    free(mapping);
    char *result = lsp_call("request", "{\\"method\\":\\"test/echo\\",\\"params\\":{\\"value\\":42}}");
    if (!result) return 1;
    puts(result);
    free(result);
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
            verify_client("C", [str(directory / "c-client")], environment, server)

            shutil.copyfile(
                ROOT / "starter_templates/java/code/src/main/java/LSPClient.java",
                directory / "LSPClient.java",
            )
            (directory / "Main.java").write_text('''class Main {
    public static void main(String[] args) throws Exception {
        var client = new LSPClient();
        System.out.println(new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(client.extensionToLanguage));
        System.out.println(client.call("request", "{\\"method\\":\\"test/echo\\",\\"params\\":{\\"value\\":42}}"));
    }
}
''')
            classpath = environment.get("CLASSPATH", "/usr/share/java/*")
            subprocess.run([
                "javac", "-cp", classpath, "-d", folder,
                str(directory / "LSPClient.java"), str(directory / "Main.java")
            ], check=True, capture_output=True)
            verify_client("Java", ["java", "-cp", folder + os.pathsep + classpath, "Main"], environment, server)
            verify_csharp_client(directory, environment, server)
            verify_zig_client(directory, environment, server)
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == "__main__":
    main()
