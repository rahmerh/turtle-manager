local QuarriesPage = require("display.pages.quarries")
local RunnersPage = require("display.pages.runners")

local page = {}
page.__index = page

local function get_page_from_selected(self, selected)
    local result
    if selected == "quarries" then
        result = self.quarries_page
    elseif selected == "runners" then
        result = self.runners_page
    end

    return result
end

function page:new(monitor, layout)
    return setmetatable({
        monitor = monitor,
        layout = layout,
        quarries_page = QuarriesPage:new(monitor, layout),
        runners_page = RunnersPage:new(monitor, layout),
    }, self)
end

function page:handle_click(selected, x, y)
    local selected_page = get_page_from_selected(self, selected)

    if not selected_page then
        return false
    end

    selected_page:handle_click(x, y)

    return true
end

function page:render(selected, data)
    if not data then
        return
    end

    local selected_page = get_page_from_selected(self, selected)
    selected_page:render(data)
end

return page
