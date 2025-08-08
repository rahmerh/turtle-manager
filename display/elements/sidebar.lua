local Button = require("display.elements.button")
local Container = require("display.elements.container")

local sidebar = {}
sidebar.__index = sidebar

function sidebar:new(monitor, page_switcher, layout)
    local monitor_width, monitor_height = layout:get_monitor_size(monitor)
    local width = math.floor(monitor_width / 5)
    layout:set_page_offset(width + 1)

    local position = {
        x = 1,
        y = 1
    }

    local size = {
        width = width,
        height = monitor_height
    }

    local padding = {
        top = 1,
        right = 1,
        bottom = 1,
        left = 1
    }

    local container = Container:new(
        monitor,
        Container.layouts.manual,
        position,
        size,
        padding)

    local quarries_button = Button:new(monitor, layout, {
        size = {
            width = width - 2,
            height = 3,
        },
        text = "Quarries",
        button_color = colours.lightBlue,
        text_color = colours.black,
        on_click = function()
            if page_switcher then
                page_switcher("quarries")
            end
        end
    })

    local runners_button = Button:new(monitor, layout, {
        size = {
            width = width - 2,
            height = 3,
        },
        text = "Runners",
        button_color = colours.lightBlue,
        text_color = colours.black,
        on_click = function()
            if page_switcher then
                page_switcher("runners")
            end
        end
    })

    container:add_element(quarries_button, {
        x = 2,
        y = 2
    })
    container:add_element(runners_button, {
        x = 2,
        y = 6
    })

    return setmetatable({
        monitor = monitor,
        page_switcher = page_switcher,
        container = container
    }, sidebar)
end

function sidebar:handle_click(x, y)
    if x > self.container.size.width then
        return false
    end

    return self.container:handle_click(x, y)
end

function sidebar:render()
    local _, monitor_height = self.monitor.getSize()

    self.monitor.setBackgroundColour(colours.grey)
    for i = 1, monitor_height do
        self.monitor.setCursorPos(1, i)
        self.monitor.write(string.rep(" ", self.container.size.width))
    end

    self.container:render()
end

return sidebar
