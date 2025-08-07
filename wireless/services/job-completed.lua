local core = require("wireless._internal.core")

local PROTOCOL = "rpc"

local completed = {}

function completed.signal_completed(receiver, role)
    core.send(receiver, {
        operation = "job:completed",
        role = role
    }, PROTOCOL)
end

return completed
