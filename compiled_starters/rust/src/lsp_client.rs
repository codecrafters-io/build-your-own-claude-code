// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied client for the language server the tester starts.
use serde_json::Value;
use std::collections::HashMap;
use std::error::Error;
use std::io::{Read, Write};
use std::net::TcpStream;
use std::time::Duration;

/// Sends your agent's messages to the language server.
///
/// The client doesn't track open documents or versions; that state belongs in
/// your agent.
///
/// # Examples
///
/// ```ignore
/// if let Some(lsp) = LspClient::from_environment()? {
///     let language = &lsp.extension_to_language[".py"]; // "python"
///     let result = lsp.call("request", &serde_json::json!({"method": "textDocument/definition", "params": params}))?;
/// }
/// ```
pub struct LspClient {
    address: String,
    path: String,
    /// Maps file extensions, including the dot, to LSP language IDs, such as
    /// `{".py": "python"}`.
    pub extension_to_language: HashMap<String, String>,
}

impl LspClient {
    /// Connects to the language server the tester configured.
    ///
    /// Returns `Ok(None)` when no language server is configured.
    ///
    /// # Errors
    ///
    /// Returns an error if connecting or reading the language mapping fails.
    pub fn from_environment() -> Result<Option<Self>, Box<dyn Error>> {
        if std::env::var_os("CODECRAFTERS_LSP_URL").is_none() {
            return Ok(None);
        }
        Ok(Some(Self::new()?))
    }

    /// Connects and reads the extension-to-language mapping.
    ///
    /// # Errors
    ///
    /// Returns an error if no language server is configured, or connecting fails.
    pub fn new() -> Result<Self, Box<dyn Error>> {
        let url = std::env::var("CODECRAFTERS_LSP_URL")?;
        let local = url
            .strip_prefix("http://127.0.0.1:")
            .ok_or("Expected local LSP transport")?;
        let (port, path) = local.split_once('/').unwrap_or((local, ""));
        let mut client = Self {
            address: format!("127.0.0.1:{port}"),
            path: if path.is_empty() {
                String::new()
            } else {
                format!("/{path}")
            },
            extension_to_language: HashMap::new(),
        };
        let configuration = client.call("configuration", &serde_json::json!({}))?;
        client.extension_to_language =
            serde_json::from_value(configuration["extensionToLanguage"].clone())?;
        Ok(client)
    }

    /// Sends one action to the language server and returns the parsed JSON response.
    ///
    /// Actions and their payloads:
    ///
    ///   - "configuration": {}. Returns {"extensionToLanguage": {".py": "python"}}.
    ///   - "notify": {"method": ..., "params": {...}}, an LSP notification.
    ///     Returns null.
    ///   - "request": {"method": ..., "params": {...}}, an LSP request. Returns the
    ///     server's result, which may be null, an object, or an array.
    ///   - "notifications": {"after": cursor, "timeoutMs": ms}. Returns
    ///     {"cursor": n, "notifications": [...]}: the server's notifications after
    ///     the cursor, each with "method" and "params". Waits up to ms (0 to 5000)
    ///     when none are queued yet. Pass the returned cursor as "after" next time.
    ///
    /// # Errors
    ///
    /// Returns an error when the language server returns an error, times out
    /// (5 seconds for a request), or exits. Its message is the transport's JSON,
    /// such as `{"error":"language server exited before responding to textDocument/definition"}`.
    pub fn call(&self, action: &str, payload: &Value) -> Result<Value, Box<dyn Error>> {
        let body = serde_json::to_string(payload)?;
        let mut stream = TcpStream::connect(&self.address)?;
        stream.set_read_timeout(Some(Duration::from_secs(10)))?;
        stream.set_write_timeout(Some(Duration::from_secs(10)))?;
        write!(
            stream,
            "POST {}/{} HTTP/1.0\r\nHost: {}\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            self.path,
            action,
            self.address,
            body.len(),
            body
        )?;
        let mut response = String::new();
        stream.read_to_string(&mut response)?;
        let (headers, result) = response
            .split_once("\r\n\r\n")
            .ok_or("Invalid transport response")?;
        if headers.split_whitespace().nth(1) != Some("200") {
            return Err(result.to_owned().into());
        }
        Ok(serde_json::from_str(result)?)
    }
}
