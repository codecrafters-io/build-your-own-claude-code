#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <string>

#include <cpr/cpr.h>
#include <nlohmann/json.hpp>

namespace {
std::string parse_prompt(int argc, char* argv[]) {
    for (int i = 1; i < argc; ++i) {
        if (std::string(argv[i]) == "-p" && i + 1 < argc) {
            return argv[i + 1];
        }
    }

    throw std::runtime_error("error: -p flag is required");
}
}  // namespace

int main(int argc, char* argv[]) {
    const std::string prompt = parse_prompt(argc, argv);

    const char* api_key_env = std::getenv("OPENROUTER_API_KEY");
    if (api_key_env == nullptr || std::string(api_key_env).empty()) {
        throw std::runtime_error("OPENROUTER_API_KEY is not set");
    }

    const char* base_url_env = std::getenv("OPENROUTER_BASE_URL");
    const std::string base_url =
        (base_url_env == nullptr || std::string(base_url_env).empty())
            ? "https://openrouter.ai/api/v1"
            : base_url_env;

    nlohmann::json payload = {
        {"model", "anthropic/claude-haiku-4.5"},
        {"messages", nlohmann::json::array(
                         {{{"role", "user"}, {"content", prompt}}})},
    };

    cpr::Response response = cpr::Post(
        cpr::Url{base_url + "/chat/completions"},
        cpr::Header{{"Authorization", "Bearer " + std::string(api_key_env)},
                    {"Content-Type", "application/json"}},
        cpr::Body{payload.dump()});

    if (response.error.code != cpr::ErrorCode::OK) {
        throw std::runtime_error(response.error.message);
    }
    if (response.status_code < 200 || response.status_code >= 300) {
        throw std::runtime_error("request failed with status code " +
                                 std::to_string(response.status_code));
    }

    nlohmann::json parsed = nlohmann::json::parse(response.text);
    if (!parsed.contains("choices") || !parsed["choices"].is_array() ||
        parsed["choices"].empty() || !parsed["choices"][0].contains("message") ||
        !parsed["choices"][0]["message"].contains("content") ||
        !parsed["choices"][0]["message"]["content"].is_string()) {
        throw std::runtime_error("no choices in response");
    }

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    std::cerr << "Logs from your program will appear here!" << std::endl;

    // TODO: Uncomment the line below to pass the first stage
    // std::cout << parsed["choices"][0]["message"]["content"].get<std::string>() << std::endl;

    return 0;
}
