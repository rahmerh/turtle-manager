local list = require("lib.list")

local runners_page = {}
runners_page.__index = runners_page

function runners_page:new(monitor, layout)
    return setmetatable({
        monitor = monitor,
        layout = layout
    }, self)
end

function runners_page:render(data)
    local runners = list.filter_by(data, "role", "runner")

    local temp = 1
    for key, turtle in pairs(runners) do
        self.monitor.setCursorPos(self.layout.sidebar_width + 1, temp)
        self.monitor.write(key .. " " .. turtle.role)

        temp = temp + 1
    end
end

return runners_page
