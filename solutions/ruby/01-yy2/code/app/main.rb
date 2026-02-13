require "openai"
require "optparse"

api_key = ENV["OPENROUTER_API_KEY"]
base_url = ENV.fetch("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")

prompt = nil
OptionParser.new do |opts|
  opts.on("-p PROMPT") { |p| prompt = p }
end.parse!

raise "OPENROUTER_API_KEY is not set" unless api_key
raise "-p flag is required" unless prompt

client = OpenAI::Client.new(access_token: api_key, uri_base: base_url)

response = client.chat(
  parameters: {
    model: "anthropic/claude-haiku-4.5",
    messages: [{ role: "user", content: prompt }]
  }
)

choices = response.dig("choices")
raise "no choices in response" if choices.nil? || choices.empty?

puts choices[0].dig("message", "content")
