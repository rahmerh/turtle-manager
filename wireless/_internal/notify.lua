local core   = require("wireless._internal.core")

local notify = {}

function notify.send(receiver, operation, protocol, data)
    local payload = {
        operation = operation,
        data = data
    }

    return core.send(receiver, payload, protocol)
end

return notify
