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
