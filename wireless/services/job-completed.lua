local notify = require("wireless._internal.notify")
local core = require("wireless._internal.core")

local completed = {}

function completed.quarry_done(receiver, last_known_location)
    notify.send(receiver, "job:completed", core.protocols.notify, {
        job_type = "quarry",
        coordinates = last_known_location,
    })
end

function completed.pickup_done(receiver, what)
    notify.send(receiver, "job:completed", core.protocols.notify, {
        job_type = "pickup",
        what = what,
    })
end

return completed
