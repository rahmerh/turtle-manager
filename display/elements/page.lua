local QuarriesPage = require("display.pages.quarries")
local RunnersPage = require("display.pages.runners")

local page = {}
page.__index = page

function page:new(monitor, layout)
    return setmetatable({
        monitor = monitor,
        layout = layout,
        quarries_page = QuarriesPage:new(monitor, layout),
        runners_page = RunnersPage:new(monitor, layout),
    }, self)
end

function page:render(selected, data)
    if not data then
        return
    end

    if selected == "quarries" then
        self.quarries_page:render(data)
    elseif selected == "runners" then
        self.runners_page:render(data)
    end
end

return page
