local InfoBlock = require("display.elements.info_block")
local Pager = require("display.elements.pager")

local list = require("lib.list")

local quarries_page = {}
quarries_page.__index = quarries_page

local default_block_boundaries = {
    width = 20,
    height = 5
}

local function calculate_blocks_per_page(layout, block_width, block_height)
    local y_offset = 2
    local x_offset = layout.sidebar_width + 2
    local fit_count = 0

    while true do
        if not layout:does_element_fit_vertically(y_offset, block_height) then
            x_offset = x_offset + block_width + 1
            y_offset = 2
        end

        if not layout:does_element_fit_horizontally(x_offset, block_width) then
            break
        end

        y_offset = y_offset + block_height + 2
        fit_count = fit_count + 1
    end

    return fit_count
end

function quarries_page:new(monitor, layout)
    local result = setmetatable({
        monitor = monitor,
        layout = layout,
    }, self)

    result.blocks_per_page = calculate_blocks_per_page(
        layout,
        default_block_boundaries.width,
        default_block_boundaries.height)

    result.pager = Pager:new(monitor, layout)

    return result
end

function quarries_page:handle_click(x, y)
    if self.pager then
        self.pager:handle_click(x, y)
    end
end

function quarries_page:render(data)
    local quarries = list.filter_by(data, "role", "quarry")

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
    for key, turtle in pairs(quarries) do
        if index <= (self.blocks_per_page * (self.pager.current_page - 1)) then
            index = index + 1
            goto continue
        end

        if index > (self.blocks_per_page * self.pager.current_page) then
            break
        end

        if not self.layout:does_element_fit_vertically(y_offset, default_block_boundaries.height) then
            x_offset = x_offset + default_block_boundaries.width + 1
            y_offset = 2
        end

        default_block_boundaries.x = x_offset
        default_block_boundaries.y = y_offset

        local block_colour
        if turtle.metadata.status == "Offline" then
            block_colour = colours.red
        elseif turtle.metadata.status == "Stale" then
            block_colour = colours.yellow
        else
            block_colour = colours.green
        end

        local opts = {
            block_colour = block_colour,
            text_colour = colours.black
        }

        local location_line
        if turtle.metadata.current_location then
            location_line = ("%d %d %d"):format(
                turtle.metadata.current_location.x,
                turtle.metadata.current_location.y,
                turtle.metadata.current_location.z)
        end

        local lines = {
            key,
            turtle.metadata.status,
            location_line
        }

        local block = InfoBlock:new(self.monitor, default_block_boundaries, opts, lines, self.layout)
        block:render()

        y_offset = y_offset + default_block_boundaries.height + 2

        index = index + 1

        ::continue::
    end
end

return quarries_page
