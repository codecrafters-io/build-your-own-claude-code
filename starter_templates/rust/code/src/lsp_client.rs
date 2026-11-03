// Course-supplied transport. This client talks only to the local HTTP bridge.
use serde_json::Value;
use std::error::Error;
use std::io::{Read, Write};
use std::net::TcpStream;
use std::time::Duration;

pub struct LspClient {
    address: String,
    path: String,
}

impl LspClient {
    pub fn new() -> Result<Self, Box<dyn Error>> {
        let url = std::env::var("CODECRAFTERS_LSP_URL")?;
        let local = url
            .strip_prefix("http://127.0.0.1:")
            .ok_or("Expected local LSP transport")?;
        let (port, path) = local.split_once('/').unwrap_or((local, ""));
        Ok(Self {
            address: format!("127.0.0.1:{port}"),
            path: if path.is_empty() {
                String::new()
            } else {
                format!("/{path}")
            },
        })
    }

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
