local monitor_helper = {}
monitor_helper.__index = monitor_helper

function monitor_helper:new(monitor)
    monitor.setTextScale(0.5)

    return setmetatable({
        monitor = monitor,
    }, self)
end

function monitor_helper:clear()
    self.monitor.clear()
end

function monitor_helper:get_monitor_size()
    return self.monitor.getSize()
end

function monitor_helper:set_page_offset(offset)
    self.page_offset = offset
end

function monitor_helper:get_page_offset()
    if not self.page_offset then
        error("Page offset is required.")
    end

    return self.page_offset
end

function monitor_helper.center_x_within(width, width_within)
    local x = (width_within / 2) - (width / 2)

    if width % 2 == 0 then
        x = x + 1
    end

    return x
end

function monitor_helper:scroll_text(x, y, text, duration)
    self.monitor.setCursorPos(x, y)

    local delay = duration / #text

    for i = 1, #text do
        self.monitor.write(text:sub(i, i))
        sleep(delay)
    end
end

function monitor_helper:set_bg_colour(colour)
    self.monitor.setBackgroundColour(colour)
end

function monitor_helper:get_default_bg_colour()
    return colours.lightGrey
end

function monitor_helper:set_fg_colour(colour)
    self.monitor.setTextColour(colour)
end

function monitor_helper:write_at(text, x, y)
    self.monitor.setCursorPos(x, y)
    self.monitor.write(text)
end

function monitor_helper:render_background()
    local width, height = self.monitor.getSize()

    self.monitor.setBackgroundColour(colours.lightGrey)
    self.monitor.setCursorPos(1, 1)

    local line = string.rep(" ", width)
    for y = 1, height do
        self.monitor.setCursorPos(1, y)
        self.monitor.write(line)
    end
end

return monitor_helper
