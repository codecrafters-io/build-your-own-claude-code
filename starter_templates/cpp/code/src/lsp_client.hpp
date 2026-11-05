// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied client for the language server the tester starts. It uses the starter's CPR and nlohmann JSON libraries.
#pragma once
#include <cstdlib>
#include <optional>
#include <stdexcept>
#include <string>
#include <cpr/cpr.h>
#include <nlohmann/json.hpp>

/**
 * @brief Sends your agent's messages to the language server.
 *
 * The client doesn't track open documents or versions; that state belongs in
 * your agent.
 *
 * @code
 * auto lsp = LSPClient::from_environment();
 * if (lsp) {
 *     std::string language = lsp->extension_to_language.at(".py"); // "python"
 *     nlohmann::json result = lsp->call("request", {{"method", "textDocument/definition"}, {"params", params}});
 * }
 * @endcode
 */
class LSPClient {
    std::string url;
public:
    /// Maps file extensions, including the dot, to LSP language IDs, such as {".py": "python"}.
    nlohmann::json extension_to_language;

    /**
     * @brief Connects to the language server the tester configured.
     * @return The client, or std::nullopt when no language server is configured.
     * @throws std::runtime_error If connecting or reading the language mapping fails.
     */
    static std::optional<LSPClient> from_environment() {
        if (!std::getenv("CODECRAFTERS_LSP_URL")) return std::nullopt;
        return LSPClient{};
    }

    /**
     * @brief Connects and reads the extension-to-language mapping.
     * @throws std::runtime_error If no language server is configured, or connecting fails.
     */
    LSPClient() {
        const char* value = std::getenv("CODECRAFTERS_LSP_URL");
        if (!value) throw std::runtime_error("Run with the course LSP transport");
        url = value;
        extension_to_language = call("configuration", nlohmann::json::object())
            .at("extensionToLanguage");
    }

    /**
     * @brief Sends one action to the language server.
     *
     * Actions and their payloads:
     * - "configuration": {}. Returns {"extensionToLanguage": {".py": "python"}}.
     * - "notify": {"method": ..., "params": {...}}, an LSP notification.
     *   Returns null.
     * - "request": {"method": ..., "params": {...}}, an LSP request. Returns the
     *   server's result, which may be null, an object, or an array.
     * - "notifications": {"after": cursor, "timeoutMs": ms}. Returns
     *   {"cursor": n, "notifications": [...]}: the server's notifications after
     *   the cursor, each with "method" and "params". Waits up to ms (0 to 5000)
     *   when none are queued yet. Pass the returned cursor as "after" next time.
     *
     * @param action "configuration", "notify", "request", or "notifications".
     * @param payload The action's payload, as above.
     * @return The parsed JSON response.
     * @throws std::runtime_error If the language server returned an error, timed
     *     out (5 seconds for a request), or exited. The message is the
     *     transport's JSON, such as
     *     {"error":"language server exited before responding to textDocument/definition"}.
     */
    nlohmann::json call(const std::string& action, const nlohmann::json& payload) {
        auto response = cpr::Post(cpr::Url{url + "/" + action},
            cpr::Header{{"Content-Type", "application/json"}}, cpr::Body{payload.dump()},
            cpr::Timeout{10000});
        if (response.status_code != 200) throw std::runtime_error(response.text);
        return nlohmann::json::parse(response.text);
    }
};
