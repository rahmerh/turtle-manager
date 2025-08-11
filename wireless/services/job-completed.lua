local core = require("wireless._internal.core")

local PROTOCOL = "rpc"

local completed = {}

function completed.signal_completed(receiver, last_known_location)
    core.send(receiver, {
        operation = "job:completed",
        coordinates = last_known_location
    }, PROTOCOL)
end

return completed
