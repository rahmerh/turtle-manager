local core = require("wireless._internal.core")

local completed = {}

function completed.quarry_done(receiver, last_known_location)
    local data = {
        job_type = "quarry",
        coordinates = last_known_location,
    }
    local payload = core.create_payload("job:completed", data)

    core.send(receiver, payload, core.protocols.job_status)
end

function completed.pickup_done(receiver, what)
    local data = {
        job_type = "pickup",
        what = what,
    }
    local payload = core.create_payload("job:completed", data)

    core.send(receiver, payload, core.protocols.job_status)
end

return completed
