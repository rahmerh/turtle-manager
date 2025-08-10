local core     = require("wireless._internal.core")

local rpc      = {}

local PROTOCOL = "rpc"

function rpc.call(receiver, operation, data)
    local payload = { data = data, operation = operation }
    local ack_operation = operation .. ":ack"

    local tries = 3
    local cap = 5
    local backoff = 0.6
    for attempt = 1, tries do
        core.send(receiver, payload, PROTOCOL)

        local deadline = os.clock() + backoff
        while true do
            local remaining = deadline - os.clock()
            if remaining <= 0 then break end
            local sender, response, proto = core.receive(remaining)

            if sender == receiver and proto == PROTOCOL and type(response) == "table" then
                if response.operation == ack_operation then
                    return true, response
                end
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

function rpc.ack(receiver, payload)
    local response = { id = payload.id, operation = payload.operation .. ":ack" }
    core.send(receiver, response, PROTOCOL)
end

return rpc
