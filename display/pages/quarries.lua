local Pager           = require("display.elements.pager")
local Button          = require("display.elements.button")
local Container       = require("display.elements.container")

local list            = require("lib.list")

local quarries_page   = {}
quarries_page.__index = quarries_page

function quarries_page:new(m, page_switcher)
    local result = setmetatable({
        m = m,
        info_blocks = {},
        page_switcher = page_switcher,
    }, self)

    result.default_button_size = {
        width = 20,
        height = 5
    }

    result.pager = Pager:new(m)

    local position = {
        x = m:get_page_offset(),
        y = 1
    }

    local monitor_width, monitor_height = m:get_monitor_size()
    local size = {
        width = monitor_width - m:get_page_offset() + 1,
        height = monitor_height
    }

    local padding = {
        top = 1,
        left = 1
    }

    result.container = Container:new(
        m,
        "horizontal_rows",
        position,
        size,
        padding)

    local max_elements = result.container:calculate_capacity(
        result.default_button_size.width,
        result.default_button_size.height)

    result.page_size = max_elements

    return result
end

function quarries_page:handle_click(x, y)
    local click_handled = false
    if self.pager then
        click_handled = self.pager:handle_click(x, y)
    end

    if not click_handled then
        click_handled = self.container:handle_click(x, y)
    end

    return click_handled
end

function quarries_page:render(data)
    self.container:clear()

    local quarries = list.filter_map_by(data.turtles, "role", "quarry")
    local quarry_list = {}

    for key, turtle in pairs(quarries) do
        turtle.id = key
        table.insert(quarry_list, turtle)
    end

    quarry_list = list.sort_by(quarry_list, "id", true)

    local skip = (self.pager.current_page - 1) * self.page_size
    local index = 0
    for _, turtle in ipairs(quarry_list) do
        if index < skip then
            index = index + 1
            goto continue
        end

        local button_colour
        if turtle.metadata.status == "Offline" then
            button_colour = colours.red
        elseif turtle.metadata.status == "Stale" then
            button_colour = colours.yellow
        elseif turtle.metadata.status == "Completed" then
            button_colour = colours.green
        else
            button_colour = colours.white
        end

        local location_line
        if turtle.metadata.current_location then
            location_line = ("%d %d %d"):format(
                turtle.metadata.current_location.x,
                turtle.metadata.current_location.y,
                turtle.metadata.current_location.z)
        end

        local lines = {
            turtle.id,
            turtle.metadata.status,
            location_line
        }

        local button = Button:new(self.m, {
            size = {
                width = self.default_button_size.width,
                height = self.default_button_size.height,
            },
            text = lines,
            button_color = button_colour,
            text_color = colours.black,
            on_click = function()
                self.page_switcher("quarry_info", turtle.id)
            end
        })

        self.container:add_element(button)
        index = index + 1

        ::continue::
    end

    self.pager:set_total_pages(math.ceil(#quarry_list / self.page_size))
    if self.pager.total_pages > 1 then
        self.pager:set_total_pages(self.pager.total_pages)

        local monitor_width, monitor_height = self.m:get_monitor_size()

        local page_width = monitor_width - self.m:get_page_offset()
        local pager_x = self.m.center_x_within(self.pager:total_width(), page_width)
        local pager_y = monitor_height - 1

        self.pager:render(pager_x + self.m:get_page_offset(), pager_y)
    end

    self.container:render()
end

return quarries_page
