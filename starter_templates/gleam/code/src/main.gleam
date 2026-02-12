import argv
import gleam/dynamic
import gleam/erlang/os
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/list

pub fn main() {
  let args = argv.load().arguments
  let prompt = case args {
    ["-p", p] -> p
    _ -> panic as "Usage: -p <prompt>"
  }

  let api_key = case os.get_env("OPENROUTER_API_KEY") {
    Ok(key) -> key
    Error(_) -> panic as "OPENROUTER_API_KEY is not set"
  }

  let base_url = case os.get_env("OPENROUTER_BASE_URL") {
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

  let assert Ok(req) = request.to(base_url <> "/chat/completions")
  let req = request.set_method(req, http.Post)
  let req = request.set_header(req, "content-type", "application/json")
  let req = request.set_header(req, "authorization", "Bearer " <> api_key)
  let req = request.set_body(req, body)

  let assert Ok(resp) = httpc.send(req)

  let decoder =
    dynamic.field(
      "choices",
      dynamic.list(dynamic.field(
        "message",
        dynamic.field("content", dynamic.string),
      )),
    )
  let assert Ok(choices) = json.decode(resp.body, decoder)
  let assert [content, ..] = choices

  // You can use print statements as follows for debugging, they'll be visible when running tests.
  io.println_error("Logs from your program will appear here!")

  // TODO: Uncomment the following line to pass the first stage
  // io.print(content)
}
