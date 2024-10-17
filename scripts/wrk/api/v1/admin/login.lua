wrk.path = "/api/v1/admin/login"
wrk.method = "POST"
wrk.headers["username"] = "admin"
wrk.headers["password"] = "NgaiLongGey"

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
