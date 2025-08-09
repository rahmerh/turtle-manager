local validator = require("lib.validator")

local container = {
    layouts = {
        horizontal_rows = "horizontal_rows",
        vertical_columns = "vertical_columns",
        manual = "manual"
    }
}
container.__index = container

local function render_elements_horizontally(self, container_x, container_y, data)
    local x = container_x + self.padding.left
    local y = container_y + self.padding.top

    local row_height = 0
    for _, entry in ipairs(self.children) do
        local child = entry.element

        -- If it doesn't horizontally, wrap to new row.
        if x + child.size.width > self.size.width + container_x then
            x = container_x + self.padding.left
            y = y + row_height + self.spacing
            row_height = 0
        end

        if y + child.size.height > self.size.height then
            break
        end

        child:render(x, y, data)

        -- Move x including spacing between elements.
        x = x + child.size.width + self.spacing

        -- Determine largest height, adjust row height to it.
        row_height = math.max(row_height, child.size.height)
    end
end

local function render_elements_vertically(self, container_x, container_y, data)
    local x = container_x + self.padding.left
    local y = container_y + self.padding.top

    local column_width = 0
    for _, entry in ipairs(self.children) do
        local child = entry.element
        -- If it doesn't fit vertically, wrap to next column.
        if y + child.size.height > self.size.height + container_y then
            y = container_y + self.padding.top
            x = x + column_width + self.spacing
            column_width = 0
        end

        if x + child.size.width > self.size.width then
            break
        end

        child:render(x, y, data)

        -- Move y including spacing between elements.
        y = y + child.size.height + self.spacing

        -- Determine widest element so far in this column.
        column_width = math.max(column_width, child.size.width)
    end
end

local function render_elements_manually(self, container_x, container_y, data)
    for _, entry in ipairs(self.children) do
        local child = entry.element

        local element_x = container_x + entry.offset.x_offset
        local element_y = container_y + entry.offset.y_offset

        if entry.offset.respect_padding then
            element_x = element_x + self.padding.left
            element_y = element_y + self.padding.top
        end

        child:render(element_x, element_y, data)
    end
end

function container:new(m, layout, size, padding)
    validator.validate_parameter(layout, "string", true, "layout")
    validator.validate_parameter(size, "table", true, "size")
    validator.validate_parameter(padding, "table", false, "padding")

    local padding_sides = { "top", "right", "bottom", "left" }

    -- Normalize missing padding fields
    local corrected_padding = {}
    for _, side in ipairs(padding_sides) do
        corrected_padding[side] = padding and padding[side] or 0
    end

    if not layout or not self.layouts[layout] then
        error("Invalid layout: " .. (layout or "nil"))
    end

    return setmetatable({
        m = m,
        layout = layout,
        size = size,
        padding = corrected_padding,
        spacing = 1,
        children = {}
    }, self)
end

--- Adds an element to the container, depending on the layout it requires more information.
---@param element any element to add.
---@return boolean true if it fits in the container, false if not.
function container:add_element(element, position_offset)
    -- TODO: More element validation, does it fit? Does it contain the correct fields?
    if type(element) ~= "table" or not element.render then
        error("Invalid element, can't render this.")
    end

    local offset
    if self.layout == self.layouts.manual and not position_offset then
        offset = {
            x_offset = 0,
            y_offset = 0,
            respect_padding = false
        }
    elseif self.layout == self.layouts.manual then
        offset = {
            x_offset = (position_offset.x_offset or 0),
            y_offset = (position_offset.y_offset or 0),
            respect_padding = position_offset.respect_padding
        }
    end

    local entry = {
        element = element,
        offset = offset
    }

    table.insert(self.children, entry)

    return true
end

function container:calculate_row_capacity(element_width, element_height)
    local usable_width = self.size.width - (self.padding.left + self.padding.right)
    local usable_height = self.size.height - (self.padding.top + self.padding.bottom)

    local columns = math.floor(usable_width / (element_width + self.spacing))
    local rows = math.floor(usable_height / (element_height + self.spacing))

    return rows * columns
end

function container:handle_click(x, y)
    local is_in_x = x >= self.latest_x and x < (self.latest_x + self.size.width)
    local is_in_y = y >= self.latest_y and y < (self.latest_y + self.size.height)

    if not is_in_x or not is_in_y then
        return false
    end

    local clicked = false
    for _, entry in ipairs(self.children) do
        local child = entry.element

        if child.handle_click then
            clicked = child:handle_click(x, y)
        end

        if clicked then
            break
        end
    end

    return clicked
end

function container:clear()
    self.children = {}
end

--- Renders the elements registered in the container, following the layout's structure.
--- Won't render any elements if they're off screen. Paging has to be done by the parent.
function container:render(x, y, data)
    self.latest_x = x
    self.latest_y = y

    if self.layout == self.layouts.horizontal_rows then
        render_elements_horizontally(self, x, y, data)
    elseif self.layout == self.layouts.vertical_columns then
        render_elements_vertically(self, x, y, data)
    elseif self.layout == self.layouts.manual then
        render_elements_manually(self, x, y, data)
    end
end

return container
