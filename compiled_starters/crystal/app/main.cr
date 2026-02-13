require "http/client"
require "json"
require "option_parser"
require "uri"

prompt = ""

OptionParser.parse do |parser|
  parser.on("-p PROMPT", "Prompt to send to LLM") { |p| prompt = p }
end

if prompt.empty?
  abort("Prompt must not be empty")
end

api_key = ENV["OPENROUTER_API_KEY"]?
base_url = ENV.fetch("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")

if api_key.nil? || api_key.empty?
  abort("OPENROUTER_API_KEY is not set")
end

uri = URI.parse(base_url)
path = uri.path.rstrip("/") + "/chat/completions"

body = {
  "model"    => "anthropic/claude-haiku-4.5",
  "messages" => [
    {"role" => "user", "content" => prompt},
  ],
}.to_json

headers = HTTP::Headers{
  "Authorization" => "Bearer #{api_key}",
  "Content-Type"  => "application/json",
}

client = HTTP::Client.new(uri)
response = client.post(path, headers: headers, body: body)

if response.status_code != 200
  abort("HTTP error: #{response.status_code} #{response.body}")
end

parsed = JSON.parse(response.body)
choices = parsed["choices"]?

if choices.nil? || choices.as_a.empty?
  abort("No choices in response")
end

# You can use print statements as follows for debugging, they'll be visible when running tests.
STDERR.puts "Logs from your program will appear here!"

# TODO: Uncomment the line below to pass the first stage
# print choices[0]["message"]["content"]
