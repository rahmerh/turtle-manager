local notify = require("wireless._internal.notify")
local rpc = require("wireless._internal.rpc")
local core = require("wireless._internal.core")

local errors = require("lib.errors")

local resupply = {}

function resupply.request(receiver, turtle_position, desired_items)
    notify.send(receiver, "resupply:request", core.protocols.notify, {
        target = turtle_position,
        desired = desired_items
    })

    local timeout = 60 * 60 -- 1 Hour
    local sender, _ = core.wait_for_response_on_operation("resupply:arrived", timeout)

    return sender
end

function resupply.dispatch(receiver, turtle_position, desired_items, job_id, requested_by)
    local id, _ = rpc.call(
        receiver,
        "resupply:dispatch",
        core.protocols.rpc, {
            target = turtle_position,
            desired = desired_items,
            requested_by = requested_by,
            job_id = job_id,
        })

    if not id then
        return nil, errors.wireless.NO_ACK
    end

    return true
end

function resupply.notify_queued(receiver, msg_id)
    rpc.respond_on(receiver, msg_id, "resupply:dispatch", core.protocols.rpc)
end

function resupply.signal_arrived(receiver)
    notify.send(receiver, "resupply:arrived", core.protocols.notify)

    core.wait_for_response_on_operation("resupply:ready", 5)
end

function resupply.signal_ready(receiver)
    notify.send(receiver, "resupply:ready", core.protocols.notify)
end

function resupply.await_done()
    core.wait_for_response_on_operation("resupply:done", 5)
end

function resupply.signal_done(receiver)
    notify.send(receiver, "resupply:done", core.protocols.notify)
end

return resupply
