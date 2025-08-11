local Button            = require("display.elements.button")

local scrollable_list   = {}
scrollable_list.__index = scrollable_list

function scrollable_list:new(m, size, fields_per_item)
    if #fields_per_item > 5 then
        error("Can't display more than 5 fields per item.")
    end

    local scroll_button_size = {
        width = 3,
        height = 2
    }

    local spacing = 1
    local result = setmetatable({
        m                       = m,
        size                    = size,
        items                   = {},
        fields_per_item         = fields_per_item,
        spacing                 = spacing,
        item_height             = 5,
        item_width              = size.width - 10,
        scroll_offset           = 0,
        scrolling_window_height = size.height - (spacing * 2),
        scroll_step_size        = 2,
    }, self)

    local scroll_up_button = Button:new(
        m,
        scroll_button_size,
        "^",
        colours.black,
        colours.white,
        function()
            result:scroll_up()
        end)

    local scroll_down_button = Button:new(
        m,
        scroll_button_size,
        "v",
        colours.black,
        colours.white,
        function()
            result:scroll_down()
        end)
    result.scroll_up_button = scroll_up_button
    result.scroll_down_button = scroll_down_button

    return result
end

function scrollable_list:handle_click(x, y)
    local handled = self.scroll_up_button:handle_click(x, y)
    if not handled then
        handled = self.scroll_down_button:handle_click(x, y)
    end
    return handled
end

function scrollable_list:scroll_up()
    if self.scroll_offset > 0 then
        self.scroll_offset = self.scroll_offset - self.scroll_step_size
    end
end

function scrollable_list:scroll_down()
    local total_list_height = #self.items * (self.item_height + self.spacing) - self.spacing
    local max_off = math.max(0, total_list_height - self.scrolling_window_height)

    if self.scroll_offset < max_off then
        self.scroll_offset = self.scroll_offset + self.scroll_step_size
    end
end

function scrollable_list:render(x, y)
    self.m:set_fg_colour(colours.black)

    local list_x        = x + self.spacing

    local window_top    = y + self.spacing
    local window_bottom = y + self.scrolling_window_height
    local current_top   = window_top - self.scroll_offset
    for index, item in ipairs(self.items) do
        if index == 1 then
            self.m:set_bg_colour(colours.orange)
        else
            self.m:set_bg_colour(colours.white)
        end

        for i = 0, self.item_height - 1 do
            local line_y = current_top + i
            if line_y > window_bottom then
                break
            end

            if line_y >= window_top then
                self.m:write_at(string.rep(" ", self.item_width), list_x, line_y)
            end
        end

        local start_at_y_offset = (#self.fields_per_item <= 3) and 1 or 0
        local text_y = current_top + start_at_y_offset
        for _, field in ipairs(self.fields_per_item) do
            if text_y > window_bottom then break end
            if text_y >= window_top then
                local field_text = ("%s: %s"):format(field, tostring(item[field]))
                self.m:write_at(field_text, list_x + 1, text_y)
            end
            text_y = text_y + 1
        end

        current_top = current_top + self.item_height + self.spacing

        if current_top > window_bottom then break end
    end

    self.scroll_up_button:render(x + self.size.width - 7, y + self.spacing)
    self.scroll_down_button:render(x + self.size.width - 7,
        y + self.scrolling_window_height - self.spacing)
end

return scrollable_list
