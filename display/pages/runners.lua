local Pager = require("display.elements.pager")
local Button = require("display.elements.button")

local list = require("lib.list")

local runners_page = {}
runners_page.__index = runners_page

function runners_page:new(monitor, layout, page_switcher)
    local result = setmetatable({
        monitor = monitor,
        layout = layout,
        current_page = 1,
        total_pages = 1,
        info_blocks = {},
        page_switcher = page_switcher
    }, self)

    result.default_block_size = {
        width = 20,
        height = 5
    }

    return result
end

function runners_page:handle_click(x, y)
    if self.pager and self.pager:handle_click(x, y) then
        return true
    end

    for _, b in ipairs(self.info_blocks) do
        if b:handle_click(x, y) then
            return true
        end
    end

    return false
end

function runners_page:render(data)
    local quarries = list.filter_map_by(data.turtles, "role", "runner")

    if self.total_pages > 1 then
        local pager = Pager:new(self.monitor, self.layout)
        pager:render()
    end

    local y_offset = 2
    local x_offset = self.layout.sidebar_width + 2
    for key, turtle in pairs(quarries) do
        local boundaries = {
            width = 20,
            height = 5
        }

        if not self.layout:does_element_fit_vertically(y_offset, boundaries.height) then
            x_offset = x_offset + boundaries.width + 1
            y_offset = 2
        end

        if not self.layout:does_element_fit_horizontally(x_offset, boundaries.width) then
            self.total_pages = self.total_pages + 1
            return
        end

        boundaries.x = x_offset
        boundaries.y = y_offset

        local button_colour
        if turtle.metadata.status == "Idle" then
            button_colour = colours.white
        elseif turtle.metadata.status == "Offline" then
            button_colour = colours.red
        elseif turtle.metadata.status == "Stale" then
            button_colour = colours.yellow
        else
            button_colour = colours.green
        end

        local lines = { key, turtle.role, turtle.metadata.status }

        local button = Button:new(self.monitor, self.layout, {
            x = x_offset,
            y = y_offset,
            width = self.default_block_size.width,
            height = self.default_block_size.height,
            text = lines,
            button_color = button_colour,
            text_color = colours.black,
            on_click = function()
            end
        })
        table.insert(self.info_blocks, button)
        button:render()

        y_offset = y_offset + boundaries.height + 2
    end
end

return runners_page
