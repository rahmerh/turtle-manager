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

function layout:does_element_fit_vertically(y, height)
    local _, monitor_height = self:get_monitor_size()

    return (y + height) <= monitor_height
end

function layout:does_element_fit_horizontally(x, width)
    local monitor_width, _ = self:get_monitor_size()

    return (x + width) <= monitor_width
end

function layout:center_x_within(width, width_within)
    local x = (width_within / 2) - (width / 2)

    if width % 2 == 0 then
        x = x + 1
    end

    return x
end

function layout:calculate_blocks_per_page(block_width, block_height)
    -- TODO: Normalize padding
    local y_offset = 2
    local x_offset = self.page_offset + 1

    local fit_count = 0
    while true do
        if not self:does_element_fit_vertically(y_offset, block_height) then
            x_offset = x_offset + block_width + 1
            y_offset = 2
        end

        if not self:does_element_fit_horizontally(x_offset, block_width) then
            break
        end

        y_offset = y_offset + block_height + 2
        fit_count = fit_count + 1
    end

    return fit_count
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
