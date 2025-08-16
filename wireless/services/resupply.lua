local core = require("wireless._internal.core")

local resupply = {
    operations = {
        request = "resupply:request",
        assign = "resupply:assign",
        accepted = "resupply:accepted",
        arrived = "resupply:arrived",
        ready = "resupply:ready",
        done = "resupply:done",
    }
}

function resupply.request(receiver, turtle_position, items)
    local data = {
        target = turtle_position,
        manifest = items
    }
    local payload = core.create_payload(resupply.operations.request, data)

    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.await_arrived()
    return core.await_response(resupply.operations.arrived, 60 * 60) -- 1 Hour
end

function resupply.assign(receiver, target, manifest, requested_by)
    local data = {
        target = target,
        manifest = manifest,
        requested_by = requested_by,
    }
    local payload = core.create_payload(resupply.operations.assign, data)

    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.accept(receiver, job_id)
    local data = {
        job_id = job_id
    }
    local payload = core.create_payload(resupply.operations.accepted, data)

    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.await_accepted()
    return core.await_response(resupply.operations.accepted, 5)
end

function resupply.arrived(receiver)
    local payload = core.create_payload(resupply.operations.arrived)
    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.ready(receiver)
    local payload = core.create_payload(resupply.operations.ready)
    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.await_ready()
    return core.await_response(resupply.operations.ready, 5)
end

function resupply.done(receiver)
    local payload = core.create_payload(resupply.operations.done)
    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.await_done()
    return core.await_response(resupply.operations.done, 5)
end

return resupply
