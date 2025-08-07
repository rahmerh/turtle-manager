local Button = require("display.elements.button")

local errors = require("lib.errors")

local pager = {}
pager.__index = pager

local function calculate_page_middle(layout)
    local monitor_width, _ = layout:get_monitor_size()
    local page_width = monitor_width - layout.sidebar_width

    local page_middle = math.floor(layout.sidebar_width + (page_width / 2))

    -- Nudge pager over 1 when the width of the page is even.
    if page_width % 2 == 0 then
        page_middle = page_middle + 1
    end

    return page_middle
end

function pager:new(monitor, layout)
    local result            = setmetatable({
        monitor = monitor,
        layout = layout,
        anchor = "bottom",
        current_page = 1,
    }, self)

    local _, monitor_height = result.layout:get_monitor_size()
    local page_middle       = calculate_page_middle(layout)

    result.buttons          = {
        Button:new(monitor, {
            x = page_middle - 15,
            y = monitor_height - 1,
            width = 5,
            height = 2,
            text = "<",
            button_color = colours.grey,
            text_color = colours.white,
            on_click = function()
                if result.current_page > 1 then
                    result.current_page = result.current_page - 1
                end
            end
        }),
        Button:new(monitor, {
            x = page_middle + 10,
            y = monitor_height - 1,
            width = 5,
            height = 2,
            text = ">",
            button_color = colours.grey,
            text_color = colours.white,
            on_click = function()
                if result.current_page < result.total_pages then
                    result.current_page = result.current_page + 1
                end
            end
        }),
    }

    return result
end

function pager:set_total_pages(total_pages)
    self.total_pages = total_pages
end

function pager:should_display(index, blocks_per_page)
    local start_index = (self.current_page - 1) * blocks_per_page + 1
    local end_index = self.current_page * blocks_per_page
    return index >= start_index and index <= end_index
end

function pager:anchor_to(side)
    if side == "top" or side == "right" or side == "left" or side == "bottom" then
        self.anchored_to = side
    else
        return nil, errors.NIL_PARAM
    end
end

function pager:handle_click(x, y)
    for _, b in ipairs(self.buttons) do
        if b:handle_click(x, y) then
            return true
        end
    end
    return false
end

function pager:render()
    if not self.total_pages then
        error("Set total pages before rendering a pager.")
    elseif self.total_pages <= 1 then
        return
    end

    local monitor_width, monitor_height = self.layout:get_monitor_size()

    for _, b in ipairs(self.buttons) do
        b:render()
    end

    local pager_text = ("Page %d of %d"):format(self.current_page, self.total_pages)

    local page_width = monitor_width - self.layout.sidebar_width
    local text_x = self.layout:calculate_x_to_float_text_in(pager_text, page_width)
    text_x = text_x + self.layout.sidebar_width

    self.monitor.setBackgroundColour(self.layout.bg_colour)
    self.monitor.setCursorPos(text_x, monitor_height)
    self.monitor.write(pager_text)
end

return pager
