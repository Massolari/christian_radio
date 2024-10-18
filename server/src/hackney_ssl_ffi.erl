-module(hackney_ssl_ffi).
-export([send_with_ssl_options/3]).

send_with_ssl_options(Method, Url, Headers) ->
    SSLOptions = [
        {verify, verify_peer},
        {cacerts, public_key:cacerts_get()},
        {ciphers, ["ECDHE-RSA-AES256-SHA384"]}
    ],
    case hackney:request(Method, Url, Headers, <<>>, [{ssl_options, SSLOptions}]) of
        {ok, StatusCode, RespHeaders, ClientRef} ->
            {ok, Body} = hackney:body(ClientRef),
            {ok, {StatusCode, RespHeaders, Body}};
        {error, Reason} ->
            {error, Reason}
    end.
