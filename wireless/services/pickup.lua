local notify = require("wireless._internal.notify")
local rpc = require("wireless._internal.rpc")
local core = require("wireless._internal.core")

local errors = require("lib.errors")

local pickup = {}

function pickup.request(receiver, pickup_position, what)
    notify.send(receiver, "pickup:request", core.protocols.notify, {
        job_type = "pickup",
        position = pickup_position,
        what = what,
    })
end

function pickup.dispatch(receiver, pickup_position, what, job_id, requested_by)
    local id, _ = rpc.call(
        receiver,
        "pickup:dispatch",
        core.protocols.rpc, {
            job_type = "pickup",
            position = pickup_position,
            what = what,
            job_id = job_id,
            requested_by = requested_by
        })

    if not id then
        return nil, errors.wireless.NO_ACK
    end

    return true
end

function pickup.notify_queued(receiver, msg_id)
    rpc.respond_on(receiver, msg_id, "pickup:dispatch", core.protocols.rpc)
end

return pickup
