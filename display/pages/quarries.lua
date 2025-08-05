local list = require("lib.list")

local quarries_page = {}
quarries_page.__index = quarries_page

function quarries_page:new(monitor, layout)
    return setmetatable({
        monitor = monitor,
        layout = layout
    }, self)
end

function quarries_page:render(data)
    local quarries = list.filter_by(data, "role", "quarry")

    local temp = 1
    for key, turtle in pairs(quarries) do
        self.monitor.setCursorPos(self.layout.sidebar_width + 1, temp)
        self.monitor.write(key .. " " .. turtle.role)

        temp = temp + 1
    end
end

return quarries_page
