local Layout = {}
Layout.__index = Layout

function Layout:new(monitor)
    monitor.setTextScale(0.5)

    return setmetatable({
        monitor = monitor,
        bg_colour = colours.lightGrey
    }, self)
end

function Layout:get_monitor_size()
    return self.monitor.getSize()
end

function Layout:set_bg_colour(colour)
    self.bg_colour = colour
end

function Layout:set_sidebar_width(width)
    self.sidebar_width = width
end

function Layout:does_element_fit_vertically(y, height)
    local _, monitor_height = self:get_monitor_size()

    return (y + height) <= monitor_height
end

function Layout:does_element_fit_horizontally(x, width)
    local monitor_width, _ = self:get_monitor_size()

    return (x + width) <= monitor_width
end

function Layout:calculate_x_to_float_text_in(text, width)
    return (width / 2) - (string.len(text) / 2)
end

function Layout:scroll_text(x, y, text, duration)
    self.monitor.setCursorPos(x, y)

    local delay = duration / #text

    for i = 1, #text do
        self.monitor.write(text:sub(i, i))
        sleep(delay)
    end
end

function Layout:render_background()
    local width, height = self.monitor.getSize()

    self.monitor.setBackgroundColour(self.bg_colour)
    self.monitor.setCursorPos(1, 1)

    local line = string.rep(" ", width)
    for y = 1, height do
        self.monitor.setCursorPos(1, y)
        self.monitor.write(line)
    end
end

return Layout
