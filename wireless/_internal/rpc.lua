local core   = require("wireless._internal.core")

local errors = require("lib.errors")

local rpc    = {}

function rpc.call(receiver, operation, protocol, data)
    local payload = { data = data, operation = operation }

    local tries = 3
    local cap = 5
    local backoff = 0.6
    for attempt = 1, tries do
        local _, message_id = core.send(receiver, payload, protocol)

        local response = core.wait_for_response_on(message_id, backoff)
        if response ~= nil then
            return message_id, response
        end

        if attempt < tries then
            local next_window = math.min(cap, backoff * 2)
            local jitter = math.random() * next_window
            sleep(jitter)
            backoff = next_window
        end
    end

    return nil, errors.wireless.TIMEOUT
end

function rpc.respond_on(receiver, id, operation, protocol, data)
    local payload = {
        id = id,
        data = data,
        operation = operation,
    }

    core.send(receiver, payload, protocol)
end

return rpc
