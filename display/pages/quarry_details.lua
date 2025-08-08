local Container             = require("display.elements.container")
local Button                = require("display.elements.button")
local Label                 = require("display.elements.label")

local colour_helper         = require("display.colour_helper")

local list                  = require("lib.list")

local quarry_details_page   = {}
quarry_details_page.__index = quarry_details_page

function quarry_details_page:new(m, page_switcher)
    local buttons_container_position = {
        x = m:get_page_offset(),
        y = 1
    }

    local _, monitor_height = m:get_monitor_size()
    local buttons_container_size = {
        width = 15,
        height = monitor_height
    }

    local buttons_container = Container:new(
        m,
        Container.layouts.manual,
        buttons_container_position,
        buttons_container_size)

    local back_button = Button:new(m, {
        size = {
            height = 3,
            width = 10
        },
        text = "<< Back",
        button_colour = colours.lightBlue,
        text_colour = colours.black,
        on_click = function()
            page_switcher("quarries")
        end
    })

    buttons_container:add_element(back_button, {
        x_offset = 1,
        y_offset = buttons_container_size.height - 4
    })

    local information_container_position = {
        x = m:get_page_offset() + buttons_container_size.width + 2,
        y = 2
    }

    local information_container_size = {
        width = 10,
        height = 10
    }

    local information_container = Container:new(
        m,
        Container.layouts.vertical_columns,
        information_container_position,
        information_container_size)

    return setmetatable({
        m = m,
        page_switcher = page_switcher,
        buttons_container = buttons_container,
        information_container = information_container,
    }, self)
end

function quarry_details_page:handle_click(x, y)
    return self.buttons_container:handle_click(x, y)
end

function quarry_details_page:render(data)
    local turtles = list.convert_map_to_array(data.turtles, "id")

    local selected_turtle = list.find(turtles, "id", data.selected_id)
    if not selected_turtle then return end

    local label_size = {
        height = 3,
        width = 13
    }

    local label_colour = colour_helper.quarry_status_to_colour(selected_turtle.metadata.status)

    local status_label = Label:new(
        self.m,
        label_size,
        selected_turtle.metadata.status,
        label_colour,
        colours.black)

    self.buttons_container:add_element(status_label, {
        x_offset = 1,
        y_offset = 1
    })

    self.buttons_container:render()
    self.information_container:render()
end

return quarry_details_page
