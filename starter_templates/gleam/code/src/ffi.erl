-module(ffi).
-export([get_env/1, http_post/3]).

get_env(Name) ->
    case os:getenv(binary_to_list(Name)) of
        false -> {error, nil};
        Value -> {ok, list_to_binary(Value)}
    end.

http_post(Url, Headers, Body) ->
    application:ensure_all_started(inets),
    application:ensure_all_started(ssl),
    UrlStr = binary_to_list(Url),
    HeadersList = [{binary_to_list(K), binary_to_list(V)} || {K, V} <- Headers],
    case httpc:request(post, {UrlStr, HeadersList, "application/json", Body}, [{ssl, [{verify, verify_none}]}], []) of
        {ok, {{_, _StatusCode, _}, _RespHeaders, RespBody}} ->
            {ok, list_to_binary(RespBody)};
        {error, Reason} ->
            {error, Reason}
    end.
