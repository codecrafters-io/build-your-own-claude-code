#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
#include <cjson/cJSON.h>

static size_t write_cb(void *ptr, size_t size, size_t nmemb, void *userdata) {
    return fwrite(ptr, size, nmemb, (FILE *)userdata);
}

int main(int argc, char *argv[]) {
    const char *prompt = NULL;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-p") == 0 && i + 1 < argc)
            prompt = argv[++i];
    }
    if (!prompt) {
        fprintf(stderr, "error: -p flag is required\n");
        return 1;
    }

    const char *api_key = getenv("OPENROUTER_API_KEY");
    const char *base_url = getenv("OPENROUTER_BASE_URL");
    if (!base_url || !*base_url) base_url = "https://openrouter.ai/api/v1";
    if (!api_key || !*api_key) {
        fprintf(stderr, "OPENROUTER_API_KEY is not set\n");
        return 1;
    }

    // Build request JSON
    cJSON *req = cJSON_CreateObject();
    cJSON_AddStringToObject(req, "model", "anthropic/claude-haiku-4.5");
    cJSON *messages = cJSON_AddArrayToObject(req, "messages");
    cJSON *msg = cJSON_CreateObject();
    cJSON_AddStringToObject(msg, "role", "user");
    cJSON_AddStringToObject(msg, "content", prompt);
    cJSON_AddItemToArray(messages, msg);

    char *body = cJSON_PrintUnformatted(req);
    cJSON_Delete(req);

    // Use open_memstream so curl writes directly to a growable buffer
    char *resp_data = NULL;
    size_t resp_size = 0;
    FILE *resp_stream = open_memstream(&resp_data, &resp_size);

    char url[512];
    snprintf(url, sizeof(url), "%s/chat/completions", base_url);

    char auth_header[512];
    snprintf(auth_header, sizeof(auth_header), "Authorization: Bearer %s", api_key);

    curl_global_init(CURL_GLOBAL_DEFAULT);
    CURL *curl = curl_easy_init();

    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");
    headers = curl_slist_append(headers, auth_header);

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, resp_stream);

    CURLcode res = curl_easy_perform(curl);
    fclose(resp_stream);

    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    curl_global_cleanup();
    free(body);

    if (res != CURLE_OK) {
        fprintf(stderr, "curl error: %s\n", curl_easy_strerror(res));
        free(resp_data);
        return 1;
    }

    // Parse response
    cJSON *json = cJSON_Parse(resp_data);
    free(resp_data);
    if (!json) {
        fprintf(stderr, "Failed to parse response JSON\n");
        return 1;
    }

    cJSON *choices = cJSON_GetObjectItem(json, "choices");
    if (!cJSON_IsArray(choices) || cJSON_GetArraySize(choices) == 0) {
        fprintf(stderr, "no choices in response\n");
        cJSON_Delete(json);
        return 1;
    }

    cJSON *first = cJSON_GetArrayItem(choices, 0);
    cJSON *message = cJSON_GetObjectItem(first, "message");
    cJSON *content = cJSON_GetObjectItem(message, "content");

    printf("%s", cJSON_GetStringValue(content));

    cJSON_Delete(json);
    return 0;
}
