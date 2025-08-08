local validator = require("lib.validator")

local Background = {
    styles = {
        solid = "solid"
    }
}
Background.__index = Background

function Background:new(m, position, size)
    validator.validate_parameter(position, "table", true, "position")
    validator.validate_parameter(size, "table", true, "size")

    return setmetatable({
        m = m,
        position = position,
        size = size
    }, self)
end

function Background:solid(colour)
    self.style = self.styles.solid
    self.colour = colour
end

function Background:fill_container(container)
    local position = {
        x = container.position.x + container.padding.left,
        y = container.position.y + container.padding.top
    }

    local size = {
        width = container.size.width - container.padding.left - container.padding.right,
        height = container.size.height - container.padding.top - container.padding.bottom
    }

    return Background:new(container.m,
        position,
        size)
end

function Background:render()
    self.m:set_bg_colour(self.colour)

    for i = 0, self.size.height - 1 do
        self.m:write_at(string.rep(" ", self.size.width), self.position.x, self.position.y + i)
    end
end

return Background
