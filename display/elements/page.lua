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

function page:new(m, size, page_switcher, task_runner)
    return setmetatable({
        quarries_page = QuarriesPage:new(m, size, page_switcher),
        runners_page = RunnersPage:new(m, size, page_switcher),
        quarry_info_page = QuarryDetailsPage:new(m, size, page_switcher, task_runner)
    }, self)
end

function page:handle_click(x, y)
    if not self.selected_page then
        return false
    end

    self.selected_page:handle_click(x, y)

    return true
end

function page:render(x, y, data)
    self.selected_page = get_page_from_selected(self, data.selected_page)
    self.selected_page:render(x, y, data)
end

return page
