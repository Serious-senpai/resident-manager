local utils = require("utils")
local pre_request


function init(args)
    -- Pre-generate the request
    payload = "grant_type=password&username=test00000&password=test00000"
    pre_request = "POST /api/v1/login HTTP/1.1\r\n" ..
        "Accept: application/json\r\n" ..
        "Connection: keep-alive\r\n" ..
        string.format("Content-Length: %d\r\n", string.len(payload)) ..
        "Content-Type: application/x-www-form-urlencoded\r\n" ..
        "Host: localhost:8000\r\n" ..
        "Origin: http://localhost:8000\r\n" ..
        string.format("User-Agent: %s\r\n", utils.random_user_agent()) ..
        "\r\n" ..
        payload

    response = nil
end

function request()
    return pre_request
end
