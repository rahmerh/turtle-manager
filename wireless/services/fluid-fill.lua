local core = require("wireless._internal.core")

local errors = require("lib.errors")

local fluid_fill = {}

function fluid_fill.report(receiver, fluid_columns)
end

function fluid_fill.dispatch(receiver, fluid_columns, job_id)
end

function fluid_fill.notify_queued(receiver, msg_id)
end

return fluid_fill
