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
