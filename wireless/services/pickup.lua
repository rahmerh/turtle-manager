local core = require("wireless._internal.core")

local pickup = {
    operations = {
        request = "pickup:request",
        assign = "pickup:assign",
        accepted = "pickup:accepted",
    }
}

function pickup.request(receiver, target, what)
    local data = {
        job_type = "pickup",
        target = target,
        what = what,
    }
    local payload = core.create_payload(pickup.operations.request, data)

    core.send(receiver, payload, core.protocols.pickup)
end

function pickup.assign(receiver, target, what, requested_by)
    local data = {
        job_type = "pickup",
        target = target,
        what = what,
        requested_by = requested_by
    }
    local payload = core.create_payload(pickup.operations.assign, data)

    core.send(receiver, payload, core.protocols.pickup)
end

function pickup.await_accepted()
    return core.await_response(pickup.operations.accepted, 5)
end

function pickup.accept(receiver, job_id)
    local data = {
        job_id = job_id
    }
    local payload = core.create_payload(pickup.operations.accepted, data)

    core.send(receiver, payload, core.protocols.pickup)
end

return pickup
