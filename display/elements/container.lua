local container = {
    layouts = {
        horizontal_rows = "horizontal_rows",
        vertical_columns = "vertical_columns",
        manual = "manual"
    }
}
container.__index = container

local function render_elements_horizontally(self)
    local x = self.position.x + self.padding.left
    local y = self.position.y + self.padding.top

    local row_height = 0
    for _, entry in ipairs(self.children) do
        local child = entry.element
        -- If it doesn't horizontally, wrap to new row.
        if x + child.size.width > self.size.width + self.position.x then
            x = self.position.x + self.padding.left
            y = y + row_height + self.spacing
            row_height = 0
        end

        if y + child.size.height > self.size.height then
            break
        end

        child:render(x, y)

        -- Move x including spacing between elements.
        x = x + child.size.width + self.spacing

        -- Determine largest height, adjust row height to it.
        row_height = math.max(row_height, child.size.height)
    end
end

local function render_elements_vertically(self)
    local x = self.position.x + self.padding.left
    local y = self.position.y + self.padding.top

    local column_width = 0
    for _, entry in ipairs(self.children) do
        local child = entry.element
        -- If it doesn't fit vertically, wrap to next column.
        if y + child.size.height > self.size.height + self.position.y then
            y = self.position.y + self.padding.top
            x = x + column_width + self.spacing
            column_width = 0
        end

        if x + child.size.width > self.size.width then
            break
        end

        child:render(x, y)

        -- Move y including spacing between elements.
        y = y + child.size.height + self.spacing

        -- Determine widest element so far in this column.
        column_width = math.max(column_width, child.size.width)
    end
end

local function render_elements_manually(self)
    for _, entry in ipairs(self.children) do
        if not entry.position then
            error("Invalid element, requires it be registered with a position.")
        end

        local child = entry.element

        child:render(entry.position.x, entry.position.y)
    end
end

function container:new(m, layout, position, size, padding)
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
        position = position,
        size = size,
        padding = corrected_padding,
        spacing = 1,
        children = {}
    }, self)
end

--- Adds an element to the container, depending on the layout it requires more information.
---@param element any element to add.
---@return boolean true if it fails, false if not.
function container:add_element(element, position)
    if type(element) ~= "table" or not element.render then
        error("Invalid element, can't render this.")
    end

    local entry = {
        element = element,
        position = position
    }

    table.insert(self.children, entry)

    return true
end

function container:set_bg_colour(colour)
    self.bg_colour = colour
end

function container:calculate_capacity(element_width, element_height)
    local usable_width = self.size.width - (self.padding.left + self.padding.right)
    local usable_height = self.size.height - (self.padding.top + self.padding.bottom)

    local columns = math.floor(usable_width / (element_width + self.spacing))
    local rows = math.floor(usable_height / (element_height + self.spacing))

    return rows * columns
end

function container:handle_click(x, y)
    local is_in_x = x >= self.position.x and x < (self.position.x + self.size.width)
    local is_in_y = y >= self.position.y and y < (self.position.y + self.size.height)

    if not is_in_x and not is_in_y then
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
function container:render()
    if self.bg_colour then
        self.m:set_bg_colour(self.bg_colour)

        for i = 0, self.size.height - 1 do
            self.m:write_at(string.rep(" ", self.size.width), self.position.x, self.position.y + i)
        end
    end

    if self.layout == self.layouts.horizontal_rows then
        render_elements_horizontally(self)
    elseif self.layout == self.layouts.vertical_columns then
        render_elements_vertically(self)
    elseif self.layout == self.layouts.manual then
        render_elements_manually(self)
    end
end

return container
