local validator = require("lib.validator")

local Background = {
    styles = {
        solid = "solid"
    }
}
Background.__index = Background

function Background:new(m, size, respect_padding)
    validator.validate_parameter(size, "table", true, "size")

    return setmetatable({
        m = m,
        size = size,
        respect_padding = respect_padding
    }, self)
end

function Background:solid(colour)
    self.style = self.styles.solid
    self.colour = colour
end

function Background:fill_container(container, respect_padding)
    respect_padding = respect_padding or false

    local size = {
        width = container.size.width,
        height = container.size.height
    }

    if respect_padding then
        size.width = size.width - container.padding.left - container.padding.right
        size.height = size.height - container.padding.top - container.padding.bottom
    end

    return Background:new(container.m, size, respect_padding)
end

function Background:render(x, y)
    self.m:set_bg_colour(self.colour)

    for i = 0, self.size.height - 1 do
        self.m:write_at(string.rep(" ", self.size.width), x, y + i)
    end
end

return Background
