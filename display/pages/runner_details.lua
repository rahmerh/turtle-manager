local Container             = require("display.elements.container")
local Button                = require("display.elements.button")
local Label                 = require("display.elements.label")
local Background            = require("display.elements.background")

local stc                   = require("display.status_to_colour")

local list                  = require("lib.list")

local runner_details_page   = {}
runner_details_page.__index = runner_details_page

function runner_details_page:new(m, size, page_switcher, task_runner)
    local buttons_container_size = {
        width = 20,
        height = size.height
    }

    local buttons_container_padding = {
        top = 1,
        bottom = 1,
        left = 2,
    }

    local buttons_container = Container:new(
        m,
        Container.layouts.manual,
        buttons_container_size,
        buttons_container_padding)

    local buttons_background = Background:fill_container(buttons_container, true)
    buttons_background:solid(colours.grey)
    buttons_container:add_element(buttons_background, {
        respect_padding = true
    })

    local back_button = Button:new(m, {
            height = 3,
            width = 10
        },
        "<< Back",
        colours.black,
        colours.lightBlue,
        function() page_switcher("runners") end)

    buttons_container:add_element(back_button, {
        respect_padding = true,
        x_offset = 1,
        y_offset = buttons_container_size.height - 6,
    })

    local label_size = {
        height = 3,
        width = 15
    }

    local status_label = Label:new(
        m,
        label_size,
        "",
        colours.white,
        colours.black,
        true)

    buttons_container:add_element(status_label, {
        x_offset = 1,
        y_offset = 1,
        respect_padding = true
    })

    return setmetatable({
        m = m,
        page_switcher = page_switcher,
        task_runner = task_runner,
        buttons_container = buttons_container,
        status_label = status_label,
    }, self)
end

function runner_details_page:render(x, y, data)
    local turtles = list.convert_map_to_array(data.turtles, "id")

    local selected_turtle = list.find(turtles, "id", data.selected_id)
    if not selected_turtle then return end

    local label_colour = stc.quarry_status_to_colour(selected_turtle.metadata.status)
    if label_colour == colours.grey then label_colour = colours.red end
    self.status_label.label_colour = label_colour
    self.status_label.text = selected_turtle.metadata.status
end

return runner_details_page
