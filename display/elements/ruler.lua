local Ruler = {}
Ruler.__index = Ruler

function Ruler:new(monitor, layout)
    return setmetatable({
        monitor = monitor,
        layout = layout
    }, self)
end

function Ruler:render()
    local width, height = self.layout:get_monitor_size()

    -- Horizontal ruler at bottom
    self.monitor.setCursorPos(1, height)
    for x = 0, width - 1 do
        if x % 2 == 0 then
            self.monitor.setBackgroundColor(colours.black)
        else
            self.monitor.setBackgroundColor(colours.yellow)
        end
        self.monitor.write(" ")
    end

    -- Vertical ruler on the left
    for y = 1, height do
        self.monitor.setCursorPos(1, y)
        if y % 2 == 0 then
            self.monitor.setBackgroundColor(colours.black)
        else
            self.monitor.setBackgroundColor(colours.yellow)
        end
        self.monitor.write(" ")
    end
end

return Ruler
