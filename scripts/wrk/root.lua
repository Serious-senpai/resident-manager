local utils = require("utils")

local user_agent = utils.random_user_agent()
print("User-Agent: " .. user_agent)

wrk.scheme = "http"
wrk.host = "localhost"
wrk.port = 8000
wrk.method = "GET"
wrk.path = "/"
wrk.headers = {
    ["User-Agent"] = user_agent,
}
wrk.body = nil
