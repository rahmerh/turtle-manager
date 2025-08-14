local core = require("wireless._internal.core")
local rpc = require("wireless._internal.rpc")

local fluid_fill = {}

local PROTOCOL = "rpc"

function fluid_fill.report(receiver, fluid_columns)
    core.send(receiver, {
        operation = "fluid_fill:report",
        fluid_columns = fluid_columns
    }, PROTOCOL)
end

function fluid_fill.dispatch(receiver, fluid_columns)
    return rpc.call(receiver, "fluid_fill:dispatch", fluid_columns)
end

return fluid_fill
