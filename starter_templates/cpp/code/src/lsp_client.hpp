// Course-supplied transport, using the starter's existing HTTP and JSON libraries.
#pragma once
#include <cstdlib>
#include <stdexcept>
#include <string>
#include <cpr/cpr.h>
#include <nlohmann/json.hpp>

class LSPClient {
    std::string url;
public:
    LSPClient() {
        const char* value = std::getenv("CODECRAFTERS_LSP_URL");
        if (!value) throw std::runtime_error("Run with the course LSP transport");
        url = value;
    }
    nlohmann::json call(const std::string& action, const nlohmann::json& payload) {
        auto response = cpr::Post(cpr::Url{url + "/" + action},
            cpr::Header{{"Content-Type", "application/json"}}, cpr::Body{payload.dump()},
            cpr::Timeout{10000});
        if (response.status_code != 200) throw std::runtime_error(response.text);
        return nlohmann::json::parse(response.text);
    }
};
