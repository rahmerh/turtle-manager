local QuarriesPage = require("display.pages.quarries")
local RunnersPage = require("display.pages.runners")
local QuarryDetailsPage = require("display.pages.quarry_details")

local page = {
    pages = {
        quarries = "quarries",
        runners = "runners",
        quarry_info = "quarry_info"
    }
}
page.__index = page

local function get_page_from_selected(self, selected)
    local result
    if selected == page.pages.quarries then
        result = self.quarries_page
    elseif selected == page.pages.runners then
        result = self.runners_page
    elseif selected == page.pages.quarry_info then
        result = self.quarry_info_page
    end

    return result
end

function page:new(monitor, layout, page_switcher)
    return setmetatable({
        monitor = monitor,
        layout = layout,
        quarries_page = QuarriesPage:new(monitor, layout, page_switcher),
        runners_page = RunnersPage:new(monitor, layout, page_switcher),
        quarry_info_page = QuarryDetailsPage:new(monitor, layout, page_switcher)
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
