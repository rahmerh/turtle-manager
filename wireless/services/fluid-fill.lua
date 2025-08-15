local notify = require("wireless._internal.notify")
local core = require("wireless._internal.core")

local fluid_fill = {}

function fluid_fill.report(receiver, fluid_columns)
    notify.send(receiver, "fluid_fill:report", core.protocols.notify, fluid_columns)
end

function fluid_fill.dispatch(receiver, fluid_columns, job_id)
    notify.send(receiver, "fluid_fill:dispatch", core.protocols.notify, {
        job_id = job_id,
        fluid_columns = fluid_columns
    })
end

return fluid_fill
