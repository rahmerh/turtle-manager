local Container             = require("display.elements.container")

local quarry_details_page   = {}
quarry_details_page.__index = quarry_details_page

function quarry_details_page:new(monitor, layout, page_switcher)
    local position = {
        x = layout.page_offset + 1,
        y = 2
    }

    local _, monitor_height = layout:get_monitor_size()
    local size = {
        width = layout:get_page_width() - 2,
        height = monitor_height - 2
    }

    local container = Container:new(monitor, Container.layouts.vertical_columns, position, size)
    container:set_bg_colour(colours.grey)

    local buttons_container_size = {
        width = 15,
        height = size.height
    }

    local buttons_container = Container:new(
        monitor,
        Container.layouts.manual,
        position,
        buttons_container_size)

    container:add_element(buttons_container)

    return setmetatable({
        monitor = monitor,
        layout = layout,
        page_switcher = page_switcher,
        container = container
    }, self)
end

function quarry_details_page:handle_click(x, y)
    return false
end

function quarry_details_page:render(data)
    self.container:render()
end

return quarry_details_page
