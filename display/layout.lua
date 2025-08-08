local layout = {}
layout.__index = layout

function layout:new(monitor)
    monitor.setTextScale(0.5)

    return setmetatable({
        monitor = monitor,
        bg_colour = colours.lightGrey
    }, self)
end

function layout:get_monitor_size()
    return self.monitor.getSize()
end

function layout:get_page_width()
    local width, _ = self.monitor.getSize()
    return width - self.page_offset + 1
end

function layout:set_bg_colour(colour)
    self.bg_colour = colour
end

function layout:set_page_offset(offset)
    self.page_offset = offset
end

function layout:center_x_within(width, width_within)
    local x = (width_within / 2) - (width / 2)

    if width % 2 == 0 then
        x = x + 1
    end

    return x
end

function layout:scroll_text(x, y, text, duration)
    self.monitor.setCursorPos(x, y)

    local delay = duration / #text

    for i = 1, #text do
        self.monitor.write(text:sub(i, i))
        sleep(delay)
    end
end

function layout:render_background()
    local width, height = self.monitor.getSize()

    self.monitor.setBackgroundColour(self.bg_colour)
    self.monitor.setCursorPos(1, 1)

    local line = string.rep(" ", width)
    for y = 1, height do
        self.monitor.setCursorPos(1, y)
        self.monitor.write(line)
    end
end

return layout
