import argv
import gleam/dynamic
import gleam/dynamic/decode
import gleam/io
import gleam/json

@external(erlang, "ffi", "get_env")
fn get_env(name: String) -> Result(String, Nil)

@external(erlang, "ffi", "http_post")
fn http_post(
  url: String,
  headers: List(#(String, String)),
  body: String,
) -> Result(String, dynamic.Dynamic)

pub fn main() {
  let args = argv.load().arguments
  let prompt = case args {
    ["-p", p] -> p
    _ -> panic as "Usage: -p <prompt>"
  }

  let api_key = case get_env("OPENROUTER_API_KEY") {
    Ok(key) -> key
    Error(_) -> panic as "OPENROUTER_API_KEY is not set"
  }

  let base_url = case get_env("OPENROUTER_BASE_URL") {
    Ok(url) -> url
    Error(_) -> "https://openrouter.ai/api/v1"
  }

  let body =
    json.object([
      #("model", json.string("anthropic/claude-haiku-4.5")),
      #(
        "messages",
        json.preprocessed_array([
          json.object([
            #("role", json.string("user")),
            #("content", json.string(prompt)),
          ]),
        ]),
      ),
    ])
    |> json.to_string

  let assert Ok(resp_body) =
    http_post(base_url <> "/chat/completions", [
      #("authorization", "Bearer " <> api_key),
    ], body)

  let decoder = {
    use choices <- decode.field("choices", decode.list(
      decode.at(["message", "content"], decode.string),
    ))
    decode.success(choices)
  }
  let assert Ok(choices) = json.parse(resp_body, decoder)
  let assert [content, ..] = choices

  // You can use print statements as follows for debugging, they'll be visible when running tests.
  io.println_error("Logs from your program will appear here!")

  // TODO: Uncomment the following line to pass the first stage
  // io.print(content)
}
