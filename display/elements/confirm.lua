local Button = require("display.elements.button")
local Text = require("display.elements.text")

local confirm = {}
confirm.__index = confirm

function confirm:new(m, text)
    local monitor_width, monitor_height = m:get_monitor_size()

    local offset = {
        x_offset = 20,
        y_offset = 4
    }

    local size = {
        width = monitor_width - (offset.x_offset * 2),
        height = monitor_height - (offset.y_offset * 2)
    }

    local result = setmetatable({
        m = m,
        size = size,
        offset = offset,
        should_render = false,
    }, self)

    local confirm_button_size = {
        width = 10,
        height = 3
    }

    local yes_button = Button:new(m,
        confirm_button_size,
        "Yes",
        colours.black,
        colours.green,
        function()
            if not result.on_yes then
                error("No on_yes set for this confirm.")
            end

            result.on_yes()
            result.should_render = false
        end)
    result.yes_button = yes_button

    local no_button = Button:new(m,
        confirm_button_size,
        "No",
        colours.black,
        colours.red,
        function()
            result.should_render = false
        end)
    result.no_button = no_button

    local confirmation_text = Text:new(m, text, colours.black)
    result.confirmation_text = confirmation_text

    return result
end

function confirm:is_opened_for(id)
    return self.should_render and self.id == id
end

function confirm:open(id)
    self.should_render = true
    self.id = id
end

function confirm:close()
    self.should_render = false
    self.id = nil
end

function confirm:handle_click(x, y)
    local monitor_width, monitor_height = self.m:get_monitor_size()

    local is_in_x = x >= self.offset.x_offset and x < monitor_width - self.offset.x_offset
    local is_in_y = y >= self.offset.y_offset and y < monitor_height - self.offset.y_offset

    if not is_in_x or not is_in_y then
        self.should_render = false
        return true
    end

    local handled = self.no_button:handle_click(x, y)
    if not handled then
        handled = self.yes_button:handle_click(x, y)
    end

    return handled
end

function confirm:render()
    for i = 0, self.size.height - 1 do
        self.m:set_bg_colour(colours.lightGrey)
        self.m:write_at(string.rep(" ", self.size.width), self.offset.x_offset, self.offset.y_offset + i)

        if i > 0 then
            self.m:set_bg_colour(colours.black)
            self.m:write_at(" ", self.offset.x_offset + self.size.width, self.offset.y_offset + i)
        end
    end

    self.m:set_bg_colour(colours.black)
    self.m:write_at(string.rep(" ", self.size.width),
        self.offset.x_offset + 1,
        self.offset.y_offset + self.size.height)
    self.m:set_bg_colour(colours.lightGrey)

    local text_y = self.offset.y_offset + 3
    local text_x = self.offset.x_offset + 3
    self.confirmation_text:render(text_x, text_y)

    local button_y       = self.offset.y_offset + self.size.height - self.yes_button.size.height - 1
    local right_button_x = self.offset.x_offset + self.size.width - self.no_button.size.width - 3

    self.yes_button:render(self.offset.x_offset + 3, button_y)
    self.no_button:render(right_button_x, button_y)
end

return confirm
