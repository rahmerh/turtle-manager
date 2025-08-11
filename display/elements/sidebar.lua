local Button = require("display.elements.button")
local Container = require("display.elements.container")
local Background = require("display.elements.background")

local sidebar = {}
sidebar.__index = sidebar

function sidebar:new(m, size, page_switcher)
    local padding = {
        top = 1,
        right = 1,
        bottom = 1,
        left = 1
    }

    local container = Container:new(
        m,
        Container.layouts.manual,
        size,
        padding)

    local background = Background:fill_container(container, false)
    background:solid(colours.grey)
    container:add_background(background)

    local quarries_button = Button:new(m,
        {
            width = size.width - 2,
            height = 3,
        },
        "Quarries",
        colours.black,
        colours.lightBlue,
        function() page_switcher("quarries") end)

    local runners_button = Button:new(m,
        {
            width = size.width - 2,
            height = 3,
        },
        "Runners",
        colours.black,
        colours.lightBlue,
        function() page_switcher("runners") end)

    local settings_button = Button:new(m, {
            width = size.width - 2,
            height = 3,
        },
        "Settings",
        colours.black,
        colours.lightBlue,
        function() page_switcher("settings") end)

    container:add_element(2, quarries_button, {
        x_offset = 1,
        y_offset = 1
    })
    container:add_element(3, runners_button, {
        x_offset = 1,
        y_offset = 5
    })
    container:add_element(4, settings_button, {
        x_offset = 1,
        y_offset = size.height - 4
    })

    return setmetatable({
        m = m,
        size = size,
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
    return self.container:handle_click(x, y)
end

function sidebar:render(x, y, data)
    for name, button in pairs(self.buttons) do
        if name == data.selected_page then
            button.button_colour = colours.orange
        else
            button.button_colour = colours.lightBlue
        end
    end

    self.container:render(x, y, data)
end

return sidebar
