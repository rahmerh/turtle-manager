local block = {}
block.__index = block

function block:new(monitor, boundaries, opts, lines, layout)
    assert(boundaries.x and
        boundaries.y and
        boundaries.width and
        boundaries.height and
        opts.block_colour and
        opts.text_colour, "Invalid boundaries")
    return setmetatable({
        monitor = monitor,
        x = boundaries.x,
        y = boundaries.y,
        width = boundaries.width,
        height = boundaries.height,
        block_colour = opts.block_colour,
        text_colour = opts.text_colour,
        lines = lines,
        layout = layout,
    }, self)
end

function block:render()
    self.monitor.setTextColor(self.text_colour)
    self.monitor.setBackgroundColour(self.block_colour)

    for i = 0, self.height do
        self.monitor.setCursorPos(self.x, self.y + i)
        self.monitor.write(string.rep(" ", self.width))
    end

    for i = 1, #self.lines do
        self.monitor.setCursorPos(self.x + self.layout:calculate_x_to_float_text_in(self.lines[i], self.width),
            self.y + i)
        self.monitor.write(self.lines[i])
    end
end

return block
