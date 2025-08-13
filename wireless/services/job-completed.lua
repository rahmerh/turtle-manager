local core = require("wireless._internal.core")

local PROTOCOL = "rpc"

local completed = {}

function completed.quarry_done(receiver, last_known_location)
    core.send(receiver, {
        operation = "job:completed",
        job_type = "quarry",
        coordinates = last_known_location,
    }, PROTOCOL)
end

function completed.pickup_done(receiver, what)
    core.send(receiver, {
        operation = "job:completed",
        job_type = "pickup",
        what = what,
    }, PROTOCOL)
end

return completed
