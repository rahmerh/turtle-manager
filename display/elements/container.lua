local container = {}
container.__index = container

function container:new(monitor, layout, position, size, padding)
    local padding_sides = { "top", "right", "bottom", "left" }

    local corrected_padding = {}
    for _, side in ipairs(padding_sides) do
        corrected_padding[side] = padding and padding[side] or 0
    end

    return setmetatable({
        monitor = monitor,
        layout = layout,
        position = position,
        size = size,
        padding = corrected_padding,
        children = {}
    }, self)
end

function container:add_element(element, relative_x, relative_y)
    relative_x = relative_x or 0
    relative_y = relative_y or 0

    if type(element) ~= "table" or not element.render then
        error("Invalid element, can't render this.")
    end

    local content_x = self.position.x + self.padding.left + relative_x
    local content_y = self.position.y + self.padding.top + relative_y

    local child_element = {
        position = {
            x = content_x,
            y = content_y
        },
        element = element
    }

    table.insert(self.children, child_element)
end

function container:clear()
    self.children = {}
end

function container:render(data)
    for _, child_element in ipairs(self.children) do
        child_element.element:render(child_element.position.x, child_element.position.y, data)
    end
end

return container
