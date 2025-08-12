local Button            = require("display.elements.button")

local list              = require("lib.list")

local scrollable_list   = {}
scrollable_list.__index = scrollable_list

function scrollable_list:new(m, size, on_reorder_down, on_reorder_up, reorderable)
    reorderable = reorderable or true

    local scroll_button_size = {
        width = 4,
        height = 2
    }

    local spacing = 1
    local result = setmetatable({
        m                       = m,
        size                    = size,
        items                   = {},
        spacing                 = spacing,
        item_height             = 5,
        item_width              = size.width - 10,
        scroll_offset           = 0,
        scrolling_window_height = size.height - (spacing * 2),
        scroll_step_size        = 2,
        reorderable             = reorderable,
        reorder_buttons         = {},
        on_reorder_down         = on_reorder_down,
        on_reorder_up           = on_reorder_up,
    }, self)

    local scroll_up_button = Button:new(
        m,
        scroll_button_size,
        "/\\",
        colours.black,
        colours.white,
        function()
            result:scroll_up()
        end)

    local scroll_down_button = Button:new(
        m,
        scroll_button_size,
        "\\/",
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
    for _, button in ipairs(self.reorder_buttons) do
        local handled = button:handle_click(x, y)

        if handled then
            return handled
        end
    end

    if self.pagers_enabled then
        local handled = self.scroll_up_button:handle_click(x, y)
        if not handled then
            handled = self.scroll_down_button:handle_click(x, y)
        end
        return handled
    end
end

function scrollable_list:scroll_up()
    if self.scroll_offset > 0 then
        self.scroll_offset = self.scroll_offset - self.scroll_step_size
    end
end

function scrollable_list:scroll_down()
    local total_list_height = list.map_len(self.items) * (self.item_height + self.spacing) - self.spacing
    local max_off = math.max(0, total_list_height - self.scrolling_window_height)

    if self.scroll_offset < max_off then
        self.scroll_offset = self.scroll_offset + self.scroll_step_size
    end
end

function scrollable_list:render(x, y)
    self.m:set_fg_colour(colours.black)

    local total_list_height = list.map_len(self.items) * (self.item_height + self.spacing) - self.spacing
    self.pagers_enabled     = (total_list_height > self.scrolling_window_height)

    self.reorder_buttons    = {}

    local nudge_button_size = {
        width = 4,
        height = 2,
    }

    local list_x            = x + self.spacing

    local window_top        = y + self.spacing
    local window_bottom     = y + self.scrolling_window_height
    local current_top       = window_top - self.scroll_offset
    for index, item in ipairs(self.items) do
        local item_top      = current_top
        local item_bottom   = current_top + self.item_height - 1
        local fully_visible = (item_top >= window_top) and (item_bottom <= window_bottom)

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

        local start_at_y_offset = (list.map_len(item.display) <= 3) and 1 or 0
        local text_y = current_top + start_at_y_offset
        for _, value in ipairs(item.display) do
            if text_y > window_bottom then
                break
            end

            if text_y >= window_top then
                self.m:write_at(value, list_x + 1, text_y)
                text_y = text_y + 1
            end
        end

        if self.reorderable and fully_visible then
            local reorder_button_x = list_x + self.item_width - nudge_button_size.width
            local down_y = current_top + self.item_height - nudge_button_size.height

            local reorder_down = Button:new(self.m,
                nudge_button_size,
                "\\/",
                colours.black,
                colours.lightBlue,
                function()
                    if self.on_reorder_down then self.on_reorder_down(item.job_id) end
                end)

            if index < #self.items then
                reorder_down:render(reorder_button_x, down_y)
                table.insert(self.reorder_buttons, reorder_down)
            end

            local up_y = current_top
            local reorder_up = Button:new(self.m,
                nudge_button_size,
                "/\\",
                colours.black,
                colours.lightBlue,
                function()
                    if self.on_reorder_up then self.on_reorder_up(item.job_id) end
                end)

            if index > 1 then
                reorder_up:render(reorder_button_x, up_y)
                table.insert(self.reorder_buttons, reorder_up)
            end
        end

        current_top = current_top + self.item_height + self.spacing

        if current_top > window_bottom then break end
    end

    if self.pagers_enabled then
        self.scroll_up_button:render(x + self.size.width - 6, y + self.spacing)

        self.scroll_down_button:render(x + self.size.width - 6,
            y + self.scrolling_window_height - self.spacing)
    end
end

return scrollable_list
