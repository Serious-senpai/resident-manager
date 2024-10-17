wrk.path = "/"
wrk.method = "GET"

local request

function init(args)
    -- Pre-generate the request
    -- Usage of \r\n: RFC2616 explicitly stated that header lines must end with a CRLF sequence
    request = string.format("%s %s HTTP/1.1\r\n", wrk.method, wrk.path) ..
        "Host: localhost:8000\r\n" ..
        "Connection: keep-alive\r\n" ..
        "\r\n"

    response = nil
end

function request()
    return request
end
