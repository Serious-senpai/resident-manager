local utils = require("utils")

local user_agent = utils.random_user_agent()
print("User-Agent: " .. user_agent)

wrk.scheme = "http"
wrk.host = "localhost"
wrk.port = 8000
wrk.method = "POST"
wrk.path = "/api/v1/admin/login"
wrk.headers = {
    ["Username"] = "incorrect",
    ["Password"] = "incorrect",    
    ["User-Agent"] = user_agent,
}
wrk.body = nil

local request

function init(args)
    -- Pre-generate the request
    request = string.format("%s %s HTTP/1.1\r\n", wrk.method, wrk.path) ..
        "Host: localhost:8000\r\n" ..
        "Connection: keep-alive\r\n" ..
        string.format("Username: %s\r\n", wrk.headers["username"]) ..
        string.format("Password: %s\r\n", wrk.headers["password"]) ..
        "\r\n"

    response = nil
end

function request()
    return request
end
