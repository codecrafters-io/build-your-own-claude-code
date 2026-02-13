package main

import "base:runtime"
import "core:c"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

foreign import libcurl "system:curl"

CURL :: rawptr
CURLcode :: enum c.int {
	OK = 0,
}

curl_slist :: struct {
	data: cstring,
	next: ^curl_slist,
}

CURLOPT_WRITEDATA     :: 10001
CURLOPT_URL           :: 10002
CURLOPT_POSTFIELDS    :: 10015
CURLOPT_HTTPHEADER    :: 10023
CURLOPT_WRITEFUNCTION :: 20011
CURL_GLOBAL_DEFAULT   :: c.long(3)

@(default_calling_convention = "c")
foreign libcurl {
	curl_global_init    :: proc(flags: c.long) -> CURLcode ---
	curl_global_cleanup :: proc() ---
	curl_easy_init      :: proc() -> CURL ---
	curl_easy_cleanup   :: proc(handle: CURL) ---
	curl_easy_perform   :: proc(handle: CURL) -> CURLcode ---
	curl_easy_setopt    :: proc(handle: CURL, option: c.int, #c_vararg args: ..any) -> CURLcode ---
	curl_slist_append   :: proc(list: ^curl_slist, s: cstring) -> ^curl_slist ---
	curl_slist_free_all :: proc(list: ^curl_slist) ---
}

Response_Buffer :: struct {
	data: [dynamic]u8,
}

write_callback :: proc "c" (ptr: [^]u8, size: c.size_t, nmemb: c.size_t, userdata: rawptr) -> c.size_t {
	context = runtime.default_context()
	total := size * nmemb
	buf := cast(^Response_Buffer)userdata
	for i in 0 ..< int(total) {
		append(&buf.data, ptr[i])
	}
	return total
}

main :: proc() {
	prompt: string
	args := os.args
	for i := 1; i < len(args); i += 1 {
		if args[i] == "-p" && i + 1 < len(args) {
			prompt = args[i + 1]
		}
	}

	if prompt == "" {
		fmt.eprintln("Prompt must not be empty")
		os.exit(1)
	}

	api_key, api_key_ok := os.lookup_env("OPENROUTER_API_KEY")
	if !api_key_ok || api_key == "" {
		fmt.eprintln("OPENROUTER_API_KEY is not set")
		os.exit(1)
	}

	base_url, base_url_ok := os.lookup_env("OPENROUTER_BASE_URL")
	if !base_url_ok || base_url == "" {
		base_url = "https://openrouter.ai/api/v1"
	}

	url_cstr := strings.clone_to_cstring(fmt.tprintf("%s/chat/completions", base_url))

	Message :: struct {
		role:    string,
		content: string,
	}
	Request :: struct {
		model:    string,
		messages: []Message,
	}

	msgs := [1]Message{{role = "user", content = prompt}}
	request := Request {
		model    = "anthropic/claude-haiku-4.5",
		messages = msgs[:],
	}

	body_bytes, marshal_err := json.marshal(request)
	if marshal_err != nil {
		fmt.eprintln("Failed to marshal request")
		os.exit(1)
	}

	body_cstr := strings.clone_to_cstring(string(body_bytes))

	curl_global_init(CURL_GLOBAL_DEFAULT)
	defer curl_global_cleanup()

	curl := curl_easy_init()
	if curl == nil {
		fmt.eprintln("Failed to initialize curl")
		os.exit(1)
	}
	defer curl_easy_cleanup(curl)

	curl_easy_setopt(curl, CURLOPT_URL, url_cstr)
	curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body_cstr)

	headers: ^curl_slist = nil
	auth_hdr := strings.clone_to_cstring(fmt.tprintf("Authorization: Bearer %s", api_key))
	headers = curl_slist_append(headers, auth_hdr)
	headers = curl_slist_append(headers, "Content-Type: application/json")
	curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers)
	defer curl_slist_free_all(headers)

	response := Response_Buffer{}
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback)
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response)

	res := curl_easy_perform(curl)
	if res != .OK {
		fmt.eprintln("Request failed")
		os.exit(1)
	}

	Choice :: struct {
		message: struct {
			content: string,
		},
	}
	API_Response :: struct {
		choices: []Choice,
	}

	api_resp: API_Response
	json.unmarshal(response.data[:], &api_resp)

	if len(api_resp.choices) == 0 {
		fmt.eprintln("No choices in response")
		os.exit(1)
	}

	// You can use print statements as follows for debugging, they'll be visible when running tests.
	fmt.eprintln("Logs from your program will appear here!")

	// TODO: Uncomment the line below to pass the first stage
	// fmt.print(api_resp.choices[0].message.content)
}
