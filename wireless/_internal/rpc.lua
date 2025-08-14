local core     = require("wireless._internal.core")

local rpc      = {}

local PROTOCOL = "rpc"

function rpc.call(receiver, operation, data)
    local payload = { data = data, operation = operation }

    local tries = 3
    local cap = 5
    local backoff = 0.6
    for attempt = 1, tries do
        local _, message_id = core.send(receiver, payload, PROTOCOL)

        local deadline = os.clock() + backoff
        while true do
            local remaining = deadline - os.clock()

            if remaining <= 0 then
                break
            end

            local sender, response, protocol = core.receive(remaining)

            if sender == receiver and
                protocol == PROTOCOL and
                type(response) == "table" then
                return message_id, response
            end
        end

        if attempt < tries then
            local next_window = math.min(cap, backoff * 2)
            local jitter = math.random() * next_window
            sleep(jitter)
            backoff = next_window
        end
    end

    return nil, "e:timeout"
end

function rpc.respond_on(receiver, id, data)
    local response = { id = id, data = data }

    core.send(receiver, response, PROTOCOL)
end

return rpc
