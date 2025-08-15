local notify = require("wireless._internal.notify")
local rpc = require("wireless._internal.rpc")
local core = require("wireless._internal.core")

local errors = require("lib.errors")

local fluid_fill = {}

function fluid_fill.report(receiver, fluid_columns)
    notify.send(receiver, "fluid_fill:report", core.protocols.notify, fluid_columns)
end

function fluid_fill.dispatch(receiver, fluid_columns, job_id)
    local id, _ = rpc.call(
        receiver,
        "fluid_fill:dispatch",
        core.protocols.rpc, {
            job_id = job_id,
            fluid_columns = fluid_columns,
        })

    if not id then
        return nil, errors.wireless.NO_ACK
    end

    return true
end

function fluid_fill.notify_queued(receiver, msg_id)
    rpc.respond_on(receiver, msg_id, "fluid_fill:dispatch")
end

return fluid_fill
