local Container             = require("display.elements.container")
local Button                = require("display.elements.button")
local Label                 = require("display.elements.label")
local Background            = require("display.elements.background")
local Text                  = require("display.elements.text")
local Confirm               = require("display.elements.confirm")

local stc                   = require("display.status_to_colour")

local list                  = require("lib.list")

local quarry_details_page   = {}
quarry_details_page.__index = quarry_details_page

function quarry_details_page:new(m, size, page_switcher, task_runner)
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
        function() page_switcher("quarries") end)

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

    local pause_button = Button:new(m, {
            height = 3,
            width = 13
        },
        "Pause",
        colours.black,
        colours.lightBlue,
        function() end)

    buttons_container:add_element(pause_button, {
        respect_padding = true,
        y_offset = 5,
        x_offset = 1,
    })

    local recover_button = Button:new(m, {
            height = 3,
            width = 13,
        },
        "Recover",
        colours.black,
        colours.red,
        function() end)

    buttons_container:add_element(recover_button, {
        respect_padding = true,
        y_offset = 9,
        x_offset = 1,
    })

    local reboot_button = Button:new(m, {
            height = 3,
            width = 13,
        },
        "Reboot",
        colours.black,
        colours.red,
        function() end)

    buttons_container:add_element(reboot_button, {
        respect_padding = true,
        y_offset = 13,
        x_offset = 1,
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

    local recover_confirm_lines = {
        "Are you sure?", "",
        "This will kill the turtle and ",
        "a runner will be dispatched",
        "to recover it."
    }

    local confirm = Confirm:new(m, recover_confirm_lines)

    return setmetatable({
        m = m,
        page_switcher = page_switcher,
        task_runner = task_runner,
        buttons_container = buttons_container,
        information_container = information_container,
        status_label = status_label,
        pause_button = pause_button,
        reboot_button = reboot_button,
        recover_button = recover_button,
        confirm = confirm,
    }, self)
end

function quarry_details_page:handle_click(x, y)
    if self.confirm:is_opened_for(self.selected_id) then
        -- Consume click, let confirmation handle it.
        return self.confirm:handle_click(x, y)
    else
        self.confirm:close()
    end

    return self.buttons_container:handle_click(x, y)
end

function quarry_details_page:render(x, y, data)
    local turtles = list.convert_map_to_array(data.turtles, "id")

    local selected_turtle = list.find(turtles, "id", data.selected_id)
    if not selected_turtle then return end

    self.selected_id = data.selected_id
    if selected_turtle.metadata.status == "Offline" or selected_turtle.metadata.status == "Stale" then
        self.pause_button.text = "Pause"
        self.pause_button.button_colour = colours.lightGrey
        self.pause_button.on_click = function() end

        self.reboot_button.button_colour = colours.lightGrey
        self.reboot_button.on_click = function() end

        self.recover_button.on_click = function()
            self.task_runner:add_task(self.task_runner.tasks.recover, {
                id = selected_turtle.id,
                offline_turtle = selected_turtle
            })

            self.page_switcher("quarries")
        end
    else
        if selected_turtle.metadata.status == "Paused" then
            self.pause_button.text = "Resume"
            self.pause_button.button_colour = colours.green

            self.pause_button.on_click = function()
                self.task_runner:add_task(self.task_runner.tasks.resume, { id = selected_turtle.id })
            end
        else
            self.pause_button.text = "Pause"
            self.pause_button.button_colour = colours.lightBlue
        end

        self.recover_button.button_colour = colours.red
        self.recover_button.on_click = function()
            self.confirm:open(selected_turtle.id)
        end

        self.reboot_button.button_colour = colours.lightBlue
        self.reboot_button.on_click = function()
            self.task_runner:add_task(self.task_runner.tasks.reboot, { id = selected_turtle.id })
        end
    end

    local label_colour = stc.quarry_status_to_colour(selected_turtle.metadata.status)
    if label_colour == colours.grey then label_colour = colours.red end
    self.status_label.label_colour = label_colour
    self.status_label.text = selected_turtle.metadata.status

    self.confirm.on_yes = function()
        self.task_runner:add_task(self.task_runner.tasks.recover, { id = selected_turtle.id })
        self.page_switcher("quarries")
    end

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

    local fuel_lines = {
        ("Current fuel level: %d"):format(selected_turtle.metadata.fuel_level),
        ("Stored fuel units: %d"):format(selected_turtle.metadata.stored_fuel_units)
    }
    local fuel = Text:new(self.m, fuel_lines, colours.white)
    self.information_container:add_element(fuel, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 2
    })

    local position_lines = {
        "Position information:", "",
        ("  Currently at: %d %d %d"):format(
            selected_turtle.metadata.current_location.x,
            selected_turtle.metadata.current_location.y,
            selected_turtle.metadata.current_location.z),
        ("  Mining layer: %d out of %d"):format(
            selected_turtle.metadata.current_layer,
            selected_turtle.metadata.boundaries.layers),
        ("  Mining row: %d"):format(
            selected_turtle.metadata.current_row)
    }
    local position_info = Text:new(self.m, position_lines, colours.white)
    self.information_container:add_element(position_info, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 5
    })

    local quarry_lines = {
        "Quarry information:", "",
        ("  Dimensions: %dx%d blocks"):format(
            selected_turtle.metadata.boundaries.width,
            selected_turtle.metadata.boundaries.depth),
        ("  Total layers: %d"):format(
            selected_turtle.metadata.boundaries.layers),
        ("  Starting location: %d %d %d"):format(
            selected_turtle.metadata.boundaries.starting_position.x,
            selected_turtle.metadata.boundaries.starting_position.y,
            selected_turtle.metadata.boundaries.starting_position.z)
    }
    local quarry_info = Text:new(self.m, quarry_lines, colours.white)
    self.information_container:add_element(quarry_info, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 11
    })

    self.buttons_container:render(x, y)
    self.information_container:render(x + self.buttons_container.size.width, y)

    if self.confirm:is_opened_for(selected_turtle.id) then
        self.confirm:render()
    end
end

return quarry_details_page
