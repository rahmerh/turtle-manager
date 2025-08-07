local Button = require("display.elements.button")

local quarry_details_page = {}
quarry_details_page.__index = quarry_details_page

function quarry_details_page:new(monitor, layout, page_switcher)
    return setmetatable({
        monitor = monitor,
        layout = layout,
        page_switcher = page_switcher,
        buttons = {}
    }, self)
end

function quarry_details_page:handle_click(x, y)
    for _, b in ipairs(self.buttons) do
        if b:handle_click(x, y) then
            return true
        end
    end

    return false
end

function quarry_details_page:render(data)
    local page_width = self.layout:get_page_width()
    local _, monitor_height = self.layout:get_monitor_size()

    self.monitor.setBackgroundColour(colours.grey)

    local buttons_width = 8
    for i = 0, monitor_height - 3 do
        self.monitor.setCursorPos(self.layout.sidebar_width + 2, 2 + i)

        local button_column = string.rep(" ", buttons_width + 2)

        if i == 0 or i == monitor_height - 3 then
            button_column = string.rep(" ", page_width - 2)
        end

        local button_column_fg = string.rep(colours.toBlit(colours.grey), string.len(button_column))
        local button_column_bg = string.rep(colours.toBlit(colours.grey), string.len(button_column))

        self.monitor.blit(button_column, button_column_fg, button_column_bg)
    end

    -- x offset = sidebar + 4 (2 for sidebar to padded page and another 2 for padded info block)
    local buttons_x_offset = self.layout.sidebar_width + 3
    local y_offset = 3
    self.monitor.setCursorPos(buttons_x_offset, y_offset)

    local button = Button:new(self.monitor, self.layout, {
        x = buttons_x_offset,
        y = monitor_height - 4,
        width = buttons_width,
        height = 3,
        text = "Back",
        button_color = colours.lightBlue,
        text_color = colours.black,
        on_click = function()
            self.page_switcher("quarries")
        end
    })

    table.insert(self.buttons, button)
    button:render()

    -- Offset 8 width of button + 2 for padding
    local info_x_offset = buttons_x_offset + 10
    self.monitor.setCursorPos(info_x_offset, y_offset)

    self.monitor.setTextColour(colours.white)
    self.monitor.setBackgroundColour(colours.grey)
    self.monitor.write(("Quarry #%s"):format(data.selected_id))

    local turtle = data.turtles[data.selected_id]
end

return quarry_details_page
