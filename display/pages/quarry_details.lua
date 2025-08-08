local Container             = require("display.elements.container")

local quarry_details_page   = {}
quarry_details_page.__index = quarry_details_page

function quarry_details_page:new(m, page_switcher)
    local position = {
        x = m:get_page_offset() + 1,
        y = 2
    }

    local monitor_width, monitor_height = m:get_monitor_size()
    local size = {
        width = monitor_width - m:get_page_offset() - 1,
        height = monitor_height - 2
    }

    local container = Container:new(m, Container.layouts.vertical_columns, position, size)
    container:set_bg_colour(colours.grey)

    local buttons_container_size = {
        width = 15,
        height = size.height
    }

    local buttons_container = Container:new(
        m,
        Container.layouts.manual,
        position,
        buttons_container_size)

    container:add_element(buttons_container)

    return setmetatable({
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
