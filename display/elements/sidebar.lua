local Button = require("display.elements.button")
local Container = require("display.elements.container")
local Background = require("display.elements.background")

local sidebar = {}
sidebar.__index = sidebar

function sidebar:new(m, page_switcher)
    local monitor_width, monitor_height = m:get_monitor_size()
    local width = math.floor(monitor_width / 5)
    m:set_page_offset(width + 1)

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
        m,
        Container.layouts.manual,
        position,
        size,
        padding)

    local background = Background:fill_container(container)
    background:solid(colours.grey)
    container:add_element(background, {
        x = 1,
        y = 1
    })

    local quarries_button = Button:new(m, {
        size = {
            width = width - 2,
            height = 3,
        },
        text = "Quarries",
        button_colour = colours.lightBlue,
        text_colour = colours.black,
        on_click = function()
            if page_switcher then
                page_switcher("quarries")
            end
        end
    })

    local runners_button = Button:new(m, {
        size = {
            width = width - 2,
            height = 3,
        },
        text = "Runners",
        button_colour = colours.lightBlue,
        text_colour = colours.black,
        on_click = function()
            if page_switcher then
                page_switcher("runners")
            end
        end
    })

    local settings_button = Button:new(m, {
        size = {
            width = width - 2,
            height = 3,
        },
        text = "Settings",
        button_colour = colours.lightBlue,
        text_colour = colours.black,
        on_click = function()
            if page_switcher then
                page_switcher("settings")
            end
        end
    })

    container:add_element(quarries_button, {
        x_offset = 1,
        y_offset = 1
    })
    container:add_element(runners_button, {
        x_offset = 1,
        y_offset = 5
    })
    container:add_element(settings_button, {
        x_offset = 1,
        y_offset = size.height - 4
    })

    return setmetatable({
        m = m,
        page_switcher = page_switcher,
        container = container,
        buttons = {
            quarries = quarries_button,
            runners = runners_button,
            settings = settings_button,
        },
    }, sidebar)
end

function sidebar:handle_click(x, y)
    if x > self.container.size.width then
        return false
    end

    return self.container:handle_click(x, y)
end

function sidebar:render(selected_page)
    for name, button in pairs(self.buttons) do
        if name == selected_page then
            button.button_colour = colours.orange
        else
            button.button_colour = colours.lightBlue
        end
    end

    self.container:render()
end

return sidebar
