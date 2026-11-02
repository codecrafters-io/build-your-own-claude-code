/* Course-supplied transport. The returned JSON string belongs to the caller. */
#ifndef CODECRAFTERS_LSP_CLIENT_H
#define CODECRAFTERS_LSP_CLIENT_H
#include <curl/curl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct lsp_buffer { char *data; size_t size; };
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

static char *lsp_call(const char *action, const char *json) {
    const char *base = getenv("CODECRAFTERS_LSP_URL");
    if (!base) { fprintf(stderr, "Run with the course LSP transport\n"); return NULL; }
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
        fprintf(stderr, "LSP transport: %s\n", buffer.data ? buffer.data : curl_easy_strerror(result));
        free(buffer.data);
        return NULL;
    }
    return buffer.data;
}
#endif
