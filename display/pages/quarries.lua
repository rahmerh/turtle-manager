local Pager = require("display.elements.pager")
local Button = require("display.elements.button")

local list = require("lib.list")

local quarries_page = {}
quarries_page.__index = quarries_page

function quarries_page:new(monitor, layout, page_switcher)
    local result = setmetatable({
        monitor = monitor,
        layout = layout,
        info_blocks = {},
        page_switcher = page_switcher
    }, self)

    result.default_block_size = {
        width = 20,
        height = 5
    }

    result.blocks_per_page = layout:calculate_blocks_per_page(
        result.default_block_size.width,
        result.default_block_size.height)

    result.pager = Pager:new(monitor, layout)

    return result
end

function quarries_page:handle_click(x, y)
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

function quarries_page:render(data)
    local quarries = list.filter_map_by(data.turtles, "role", "quarry")
    local quarry_list = {}

    for key, turtle in pairs(quarries) do
        turtle.id = key
        table.insert(quarry_list, turtle)
    end

    quarry_list = list.sort_by(quarry_list, "id", true)

    local quarry_count = 0
    for _ in pairs(quarries) do
        quarry_count = quarry_count + 1
    end

    local total_pages = math.ceil(quarry_count / self.blocks_per_page)
    self.pager:set_total_pages(total_pages)
    self.pager:render()

    local y_offset = 2
    local x_offset = self.layout.sidebar_width + 2

    local index = 1
    for _, turtle in ipairs(quarry_list) do
        if not self.pager:should_display(index, self.blocks_per_page) then
            index = index + 1
            goto continue
        end

        if not self.layout:does_element_fit_vertically(y_offset, self.default_block_size.height) then
            x_offset = x_offset + self.default_block_size.width + 1
            y_offset = 2
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

        local button = Button:new(self.monitor, self.layout, {
            x = x_offset,
            y = y_offset,
            width = self.default_block_size.width,
            height = self.default_block_size.height,
            text = lines,
            button_color = button_colour,
            text_color = colours.black,
            on_click = function()
                self.page_switcher("quarry_info", turtle.id)
            end
        })
        table.insert(self.info_blocks, button)
        button:render()

        y_offset = y_offset + self.default_block_size.height + 1

        index = index + 1

        ::continue::
    end
end

return quarries_page
