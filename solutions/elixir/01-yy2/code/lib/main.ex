defmodule CLI do
  def main(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [prompt: :string], aliases: [p: :prompt])
    prompt = Keyword.get(opts, :prompt) || raise "error: -p flag is required"

    api_key = System.get_env("OPENROUTER_API_KEY") || raise "OPENROUTER_API_KEY is not set"
    base_url = System.get_env("OPENROUTER_BASE_URL") || "https://openrouter.ai/api/v1"

    response =
      Req.post!("#{base_url}/chat/completions",
        json: %{
          "model" => "anthropic/claude-haiku-4.5",
          "messages" => [%{"role" => "user", "content" => prompt}]
        },
        auth: {:bearer, api_key}
      )

    choices = response.body["choices"]

    if is_nil(choices) or choices == [] do
      raise "no choices in response"
    end

    IO.write(List.first(choices)["message"]["content"])
  end
end
