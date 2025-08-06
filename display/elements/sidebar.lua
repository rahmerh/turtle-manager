local button = require("display.elements.button")

local sidebar = {}
sidebar.__index = sidebar

function sidebar:new(monitor, page_switcher, layout)
    local monitor_width, monitor_height = layout:get_monitor_size(monitor)
    local width = math.floor(monitor_width / 5)

    local bar = setmetatable({
        monitor = monitor,
        width = width,
        height = monitor_height,
        buttons = {},
        page_switcher = page_switcher
    }, sidebar)

    bar.buttons = {
        button:new(monitor, {
            monitor = monitor,
            x = 2,
            y = 2,
            width = width - 2,
            height = 3,
            text = "Quarries",
            button_color = colours.lightBlue,
            text_color = colours.black,
            on_click = function()
                if bar.page_switcher then
                    bar.page_switcher("quarries")
                end
            end
        }),
        button:new(monitor, {
            x = 2,
            y = 6,
            width = width - 2,
            height = 3,
            text = "Runners",
            button_color = colours.lightBlue,
            text_color = colours.black,
            on_click = function()
                if bar.page_switcher then
                    bar.page_switcher("runners")
                end
            end
        }),
    }

    return bar
end

function sidebar:handle_click(x, y)
    for _, b in ipairs(self.buttons) do
        if b:handle_click(x, y) then
            return true
        end
    end
    return false
end

function sidebar:render()
    local _, h = self.monitor.getSize()
    self.monitor.setBackgroundColour(colours.grey)
    for i = 1, h do
        self.monitor.setCursorPos(1, i)
        self.monitor.write(string.rep(" ", self.width))
    end

    for _, b in ipairs(self.buttons) do
        b:render()
    end

    self.monitor.setBackgroundColour(colours.black)
end

return sidebar
