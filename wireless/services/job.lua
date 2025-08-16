local core = require("wireless._internal.core")

local job = {
    operations = {
        job_completed = "job:completed"
    }
}

function job.quarry_done(receiver, last_known_location)
    local data = {
        job_type = "quarry",
        coordinates = last_known_location,
    }
    local payload = core.create_payload(job.operations.job_completed, data)

    core.send(receiver, payload, core.protocols.job)
end

function job.pickup_done(receiver, what)
    local data = {
        job_type = "pickup",
        what = what,
    }
    local payload = core.create_payload(job.operations.job_completed, data)

    core.send(receiver, payload, core.protocols.job)
end

return job
