local errors = require("lib.errors")

local pager = {}
pager.__index = pager

function pager:new(monitor, layout)
    return setmetatable({
        monitor = monitor,
        layout = layout,
        anchor = "bottom"
    }, self)
end

function pager:anchor_to(side)
    if side == "top" or side == "right" or side == "left" or side == "bottom" then
        self.anchored_to = side
    else
        return nil, errors.NIL_PARAM
    end
end

return pager
