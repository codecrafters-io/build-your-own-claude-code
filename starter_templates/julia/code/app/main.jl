using OpenAI

function main()
    prompt = ""
    i = 1
    while i <= length(ARGS)
        if ARGS[i] == "-p" && i + 1 <= length(ARGS)
            prompt = ARGS[i + 1]
            break
        end
        i += 1
    end

    if isempty(prompt)
        error("error: -p flag is required")
    end

    api_key = get(ENV, "OPENROUTER_API_KEY", "")
    base_url = get(ENV, "OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")

    if isempty(api_key)
        error("OPENROUTER_API_KEY is not set")
    end

    response = create_chat(
        api_key,
        "anthropic/claude-haiku-4.5",
        [Dict("role" => "user", "content" => prompt)];
        url = base_url
    )

    choices = response.response["choices"]

    if isempty(choices)
        error("No choices in response")
    end

    # You can use print statements as follows for debugging, they'll be visible when running tests.
    println(stderr, "Logs from your program will appear here!")

    # TODO: Uncomment the following line to pass the first stage
    # print(choices[1]["message"]["content"])
end

main()
