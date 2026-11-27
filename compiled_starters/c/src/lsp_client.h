/* Only needed for the LSP extension.
 * You can ignore this file until you reach that extension. */
/* Course-supplied client for the language server the tester starts. */
#ifndef CODECRAFTERS_LSP_CLIENT_H
#define CODECRAFTERS_LSP_CLIENT_H
#include <curl/curl.h>
#include <cjson/cJSON.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct lsp_buffer { char *data; size_t size; };
/**
 * @brief Sends your agent's messages to the language server.
 *
 * The client doesn't track open documents or versions; that state belongs in
 * your agent. Payloads and responses are JSON strings; parse responses with
 * cJSON.
 *
 * @code
 * LSPClient lsp;
 * int status = lsp_from_environment(&lsp);
 * if (status == 1) {
 *     const char *language = cJSON_GetObjectItem(lsp.extension_to_language, ".py")->valuestring; // "python"
 *     char *result = lsp_call("request", request_json);
 *     if (!result) fprintf(stderr, "%s\n", lsp_last_error());
 *     free(result);
 *     lsp_deinit(&lsp);
 * }
 * @endcode
 */
typedef struct {
    /** Maps file extensions, including the dot, to LSP language IDs, such as
     *  {".py": "python"}. Owned by the client and freed by lsp_deinit. */
    cJSON *extension_to_language;
} LSPClient;
static char *lsp_error_data = NULL;
static const char *lsp_error_message = NULL;

/**
 * @brief The error text after lsp_call or lsp_init failed.
 * @return Borrowed text, valid until the next lsp_call or lsp_deinit, or NULL
 *     after a successful call.
 */
static const char *lsp_last_error(void) {
    return lsp_error_message;
}

static size_t lsp_append(void *data, size_t size, size_t count, void *context) {
    struct lsp_buffer *buffer = context;
    size_t bytes = size * count;
    char *next = realloc(buffer->data, buffer->size + bytes + 1);
    if (!next) return 0;
    buffer->data = next;
    memcpy(buffer->data + buffer->size, data, bytes);
    buffer->size += bytes;
    buffer->data[buffer->size] = 0;
    return bytes;
}

/**
 * @brief Sends one action to the language server.
 *
 * Actions and their payloads:
 *   - "configuration": {}. Returns {"extensionToLanguage": {".py": "python"}}.
 *   - "notify": {"method": ..., "params": {...}}, an LSP notification.
 *     Returns null.
 *   - "request": {"method": ..., "params": {...}}, an LSP request. Returns the
 *     server's result, which may be null, an object, or an array.
 *   - "notifications": {"after": cursor, "timeoutMs": ms}. Returns
 *     {"cursor": n, "notifications": [...]}: the server's notifications after
 *     the cursor, each with "method" and "params". Waits up to ms (0 to 5000)
 *     when none are queued yet. Pass the returned cursor as "after" next time.
 *
 * @param action "configuration", "notify", "request", or "notifications".
 * @param json The action's payload as a JSON string, as above.
 * @return The response as a JSON string. The caller owns it and frees it with
 *     free(). Returns NULL when the language server returns an error, times
 *     out (5 seconds for a request), or exits; lsp_last_error() then holds the
 *     transport's JSON, such as {"error":"language server exited before responding to textDocument/definition"}.
 */
static char *lsp_call(const char *action, const char *json) {
    free(lsp_error_data);
    lsp_error_data = NULL;
    lsp_error_message = "LSP transport failed";
    const char *base = getenv("CODECRAFTERS_LSP_URL");
    if (!base) {
        lsp_error_message = "Run with the course LSP transport";
        fprintf(stderr, "%s\n", lsp_error_message);
        return NULL;
    }
    char *url = malloc(strlen(base) + strlen(action) + 2);
    if (!url) return NULL;
    sprintf(url, "%s/%s", base, action);
    CURL *curl = curl_easy_init();
    if (!curl) { free(url); return NULL; }
    struct lsp_buffer buffer = {NULL, 0};
    struct curl_slist *headers = curl_slist_append(NULL, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, lsp_append);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &buffer);
    CURLcode result = curl_easy_perform(curl);
    long status = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &status);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    free(url);
    if (result != CURLE_OK || status != 200) {
        lsp_error_data = buffer.data;
        lsp_error_message = buffer.size ? lsp_error_data :
            (result != CURLE_OK ? curl_easy_strerror(result) : "LSP transport request failed");
        fprintf(stderr, "LSP transport: %s\n", lsp_error_message);
        return NULL;
    }
    if (!buffer.data) {
        lsp_error_message = "Empty LSP transport response";
        return NULL;
    }
    lsp_error_message = NULL;
    return buffer.data;
}

/**
 * @brief Connects and reads the extension-to-language mapping.
 * @return 1 on success, or 0 on failure; lsp_last_error() then says why.
 */
static int lsp_init(LSPClient *client) {
    client->extension_to_language = NULL;
    char *json = lsp_call("configuration", "{}");
    if (!json) return 0;
    cJSON *configuration = cJSON_Parse(json);
    free(json);
    cJSON *mapping = cJSON_DetachItemFromObjectCaseSensitive(
        configuration, "extensionToLanguage");
    cJSON_Delete(configuration);
    if (!cJSON_IsObject(mapping)) {
        cJSON_Delete(mapping);
        lsp_error_message = "Missing extensionToLanguage mapping";
        return 0;
    }
    client->extension_to_language = mapping;
    return 1;
}

/**
 * @brief Connects to the language server the tester configured.
 * @return 1 when connected, 0 when no language server is configured, or -1 on
 *     an initialization error; lsp_last_error() then says why. Call lsp_deinit
 *     when done.
 */
static int lsp_from_environment(LSPClient *client) {
    client->extension_to_language = NULL;
    if (!getenv("CODECRAFTERS_LSP_URL")) return 0;
    return lsp_init(client) ? 1 : -1;
}

/** @brief Frees the language mapping and any saved error text. */
static void lsp_deinit(LSPClient *client) {
    cJSON_Delete(client->extension_to_language);
    client->extension_to_language = NULL;
    free(lsp_error_data);
    lsp_error_data = NULL;
    lsp_error_message = NULL;
}
#endif
