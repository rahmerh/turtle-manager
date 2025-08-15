local core   = require("wireless._internal.core")
local router = require("wireless.router")

local errors = require("lib.errors")

local rpc    = {}

function rpc.call(receiver, operation, protocol, data)
    local payload = { operation = operation, data = data }
    local tries, cap, backoff = 3, 5, 0.6

    for attempt = 1, tries do
        local _, id = core.send(receiver, payload, protocol)
        local deadline = os.clock() + backoff

        while os.clock() < deadline do
            router.step(0)
            local resp = core.take_response(id)
            if resp then return id, (resp.data or resp) end
            sleep(0)
        end

        if attempt < tries then
            backoff = math.min(cap, backoff * 2)
            sleep(math.random() * backoff)
        end
    end

    return nil, errors.wireless.TIMEOUT
end

function rpc.respond_on(receiver, id, operation, protocol, data)
    core.send(receiver, { id = id, operation = operation, data = data }, protocol)
end

return rpc
