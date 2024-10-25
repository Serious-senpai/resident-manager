local utils = require("utils")
local pre_request


function init(args)
    -- Pre-generate the request
    pre_request = "GET / HTTP/1.1\r\n" ..
        "Accept: application/json\r\n" ..
        "Connection: keep-alive\r\n" ..
        "Host: localhost:8000\r\n" ..
        "Origin: http://localhost:8000\r\n" ..
        string.format("User-Agent: %s\r\n", utils.random_user_agent()) ..
        "\r\n"

    response = nil
end

function request()
    return pre_request
end
