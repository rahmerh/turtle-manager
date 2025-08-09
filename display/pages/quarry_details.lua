local Container             = require("display.elements.container")
local Button                = require("display.elements.button")
local Label                 = require("display.elements.label")
local Background            = require("display.elements.background")
local Text                  = require("display.elements.text")

local colour_helper         = require("display.colour_helper")

local list                  = require("lib.list")

local quarry_details_page   = {}
quarry_details_page.__index = quarry_details_page

function quarry_details_page:new(m, size, page_switcher)
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
        y_offset = buttons_container_size.height - 6,
        x_offset = 1,
        respect_padding = true
    })

    local information_container_size = {
        width = size.width - buttons_container_size.width - 2,
        height = size.height - 2
    }

    local information_container_padding = {
        top    = 1,
        right  = 1,
        bottom = 1,
        left   = 1
    }

    local information_container = Container:new(
        m,
        Container.layouts.manual,
        information_container_size,
        information_container_padding)

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

function quarry_details_page:render(x, y, data)
    local turtles = list.convert_map_to_array(data.turtles, "id")

    local selected_turtle = list.find(turtles, "id", data.selected_id)
    if not selected_turtle then return end

    local label_size = {
        height = 3,
        width = 15
    }

    local label_colour = colour_helper.quarry_status_to_colour(selected_turtle.metadata.status)
    if label_colour == colours.grey then label_colour = colours.red end

    local status_label = Label:new(
        self.m,
        label_size,
        selected_turtle.metadata.status,
        label_colour,
        colours.black)

    self.buttons_container:add_element(status_label, {
        x_offset = 1,
        y_offset = 1,
        respect_padding = true
    })

    self.information_container:clear()

    local information_background = Background:fill_container(self.information_container, false)
    information_background:solid(colours.grey)
    self.information_container:add_element(information_background, {
        respect_padding = false,
        x_offset = 1,
        y_offset = 1
    })

    local turtle_id_text = "Quarry ID: #" .. selected_turtle.id
    local turtle_id = Text:new(self.m, turtle_id_text, colours.white)
    self.information_container:add_element(turtle_id, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 1
    })

    local fuel_text = ("Current fuel level: %d"):format(selected_turtle.metadata.fuel_level)
    local fuel = Text:new(self.m, fuel_text, colours.white)
    self.information_container:add_element(fuel, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 3
    })

    local position_lines = {
        "Position information:", "",
        ("  Currently at: %d %d %d"):format(
            selected_turtle.metadata.current_location.x,
            selected_turtle.metadata.current_location.y,
            selected_turtle.metadata.current_location.z),
        ("  Mining layer: %d out of %d"):format(
            selected_turtle.metadata.current_layer,
            selected_turtle.metadata.total_layers),
        ("  Mining row: %d"):format(
            selected_turtle.metadata.current_row)
    }
    local position_info = Text:new(self.m, position_lines, colours.white)
    self.information_container:add_element(position_info, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 4
    })

    local quarry_lines = {
        "Quarry information:", "",
        ("  Dimensions: %dx%d blocks"):format(
            selected_turtle.metadata.width,
            selected_turtle.metadata.depth),
        ("  Total layers: %d"):format(
            selected_turtle.metadata.total_layers),
    }
    local quarry_info = Text:new(self.m, quarry_lines, colours.white)
    self.information_container:add_element(quarry_info, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 10
    })

    self.buttons_container:render(x, y)
    self.information_container:render(x + self.buttons_container.size.width, y)
end

return quarry_details_page
