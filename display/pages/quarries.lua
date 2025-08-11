local Pager           = require("display.elements.pager")
local Button          = require("display.elements.button")
local Container       = require("display.elements.container")

local ts              = require("display.turtle_status")

local list            = require("lib.list")

local quarries_page   = {}
quarries_page.__index = quarries_page

function quarries_page:new(m, size, page_switcher)
    local result = setmetatable({
        m = m,
        info_blocks = {},
        size = size,
        page_switcher = page_switcher,
    }, self)

    result.default_button_size = {
        width = 19,
        height = 5
    }

    result.pager = Pager:new(m)

    local padding = {
        top = 1,
        left = 3,
        right = 1,
    }

    result.container = Container:new(
        m,
        Container.layouts.horizontal_rows,
        size,
        padding)

    local max_elements = result.container:calculate_row_capacity(
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

function quarries_page:render(x, y, data)
    self.latest_x = x
    self.latest_y = y

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
            if self.container:element_exists(turtle.id) then
                self.container:remove_element(turtle.id)
            end

            index = index + 1
            goto continue
        elseif index + 1 > self.page_size then
            self.container:remove_element(turtle.id)
        end

        local button_colour = ts.quarry_status_to_colour(turtle.metadata.status)

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

        if self.container:element_exists(turtle.id) then
            self.container:update_element(turtle.id, "text", lines)
            self.container:update_element(turtle.id, "button_colour", button_colour)
        else
            local button = Button:new(self.m, {
                    width = self.default_button_size.width,
                    height = self.default_button_size.height,
                },
                lines,
                colours.black,
                button_colour,
                function() self.page_switcher("quarry_info", turtle.id) end)
            self.container:add_element(turtle.id, button)
        end
        index = index + 1


        ::continue::
    end

    self.pager:set_total_pages(math.ceil(#quarry_list / self.page_size))
    if self.pager.total_pages > 1 then
        self.pager:set_total_pages(self.pager.total_pages)

        local _, monitor_height = self.m:get_monitor_size()

        local pager_x = self.m.center_x_within(self.pager:total_width(), self.size.width)
        local pager_y = monitor_height - 1

        self.pager:render(x + pager_x + 1, pager_y)
    end

    self.container:render(x, y, data)
end

return quarries_page
