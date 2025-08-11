local Container             = require("display.elements.container")
local Button                = require("display.elements.button")
local ScrollableList        = require("display.elements.scrollable_list")
local Background            = require("display.elements.background")
local Text                  = require("display.elements.text")

local ts                    = require("display.turtle_status")

local list                  = require("lib.list")

local runner_details_page   = {}
runner_details_page.__index = runner_details_page

function runner_details_page:new(m, size, page_switcher, task_runner)
    local status_container_size = {
        width = 25,
        height = size.height
    }

    local status_container_padding = {
        top = 1,
        bottom = 1,
        left = 2,
    }

    local status_container = Container:new(
        m,
        Container.layouts.manual,
        status_container_size,
        status_container_padding)

    local status_background = Background:fill_container(status_container, true)
    status_background:solid(colours.grey)
    status_container:add_background(status_background)

    local back_button = Button:new(m, {
            height = 3,
            width = 10
        },
        "<< Back",
        colours.black,
        colours.lightBlue,
        function() page_switcher("runners") end)
    status_container:add_element(2, back_button, {
        respect_padding = true,
        x_offset = 1,
        y_offset = status_container_size.height - 6,
    })

    local runner_header_id = 3
    local runner_header = Text:new(m, "", colours.white, status_background.colour)
    status_container:add_element(runner_header_id, runner_header, {
        x_offset = 1,
        y_offset = 1,
        respect_padding = true
    })

    local fuel_id = 4
    local fuel = Text:new(m, "", colours.white, status_background.colour)
    status_container:add_element(fuel_id, fuel, {
        x_offset = 1,
        y_offset = 2,
        respect_padding = true
    })

    local inventory_contents_id = 5
    local inventory_contents = Text:new(m, "", colours.white, status_background.colour)
    status_container:add_element(inventory_contents_id, inventory_contents, {
        x_offset = 1,
        y_offset = 5,
        respect_padding = true
    })

    local task_container_size = {
        width = size.width - status_container.size.width,
        height = size.height
    }

    local task_container_padding = {
        top    = 1,
        right  = 1,
        bottom = 1,
        left   = 1
    }

    local task_container = Container:new(
        m,
        Container.layouts.manual,
        task_container_size,
        task_container_padding)

    local task_background = Background:fill_container(task_container, true)
    task_background:solid(colours.grey)
    task_container:add_background(task_background)

    local scrollable_size = {
        width = task_container_size.width,
        height = task_container_size.height,
    }

    local scrollable_id = 1
    local scrollable = ScrollableList:new(m, scrollable_size, {})
    task_container:add_element(scrollable_id, scrollable, {
        respect_padding = true
    })

    return setmetatable({
        m = m,
        page_switcher = page_switcher,
        task_runner = task_runner,
        status_container = status_container,
        task_container = task_container,
        scrollable_id = scrollable_id,
        text_elements = {
            runner_header_id = runner_header_id,
            fuel_id = fuel_id,
            inventory_contents_id = inventory_contents_id,
        }
    }, self)
end

function runner_details_page:handle_click(x, y)
    return self.status_container:handle_click(x, y)
end

function runner_details_page:render(x, y, data)
    local turtles = list.convert_map_to_array(data.turtles, "id")

    local selected_turtle = list.find(turtles, "id", data.selected_id)
    if not selected_turtle then return end

    local label_colour = ts.quarry_status_to_colour(selected_turtle.metadata.status)
    if label_colour == colours.grey then label_colour = colours.red end

    local runner_header_text = "Runner ID: #" .. selected_turtle.id
    self.status_container:update_element(
        self.text_elements.runner_header_id,
        "content",
        runner_header_text)

    local fuel_lines = {
        ("Fuel level: %d"):format(selected_turtle.metadata.fuel_level),
        ("Stored fuel: %d"):format(selected_turtle.metadata.stored_fuel_units),
    }
    self.status_container:update_element(
        self.text_elements.fuel_id,
        "content",
        fuel_lines)

    local inventory_lines = {
        "Carrying:", ""
    }
    local inventory = list.convert_map_to_array(selected_turtle.metadata.inventory_contents, "name")

    if #inventory > 0 then
        local inventory_sorted = list.sort_by(inventory, "amount", true)
        for _, item in ipairs(inventory_sorted) do
            local _, name = item.name:match("([^:]+):(.+)")
            name = name:gsub("_", " ")
            name = name:gsub("(%a)([%w_']*)", function(first, rest)
                return first:upper() .. rest:lower()
            end)

            local line = ("%s: %d"):format(name, item.amount)
            if #inventory_lines < 10 then
                table.insert(inventory_lines, line)
            else
                table.insert(inventory_lines, "...")
                break
            end
        end
    else
        table.insert(inventory_lines, "Nothing")
    end
    self.status_container:update_element(
        self.text_elements.inventory_contents_id,
        "content",
        inventory_lines)

    self.task_container:update_element(
        self.scrollable_id,
        "items",
        selected_turtle.metadata.tasks)

    self.status_container:render(x, y)
    self.task_container:render(x + self.status_container.size.width, y)
end

return runner_details_page
