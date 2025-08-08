local Button = require("display.elements.button")

local errors = require("lib.errors")

local pager = {}
pager.__index = pager

function pager:new(monitor, layout)
    local result        = setmetatable({
        monitor = monitor,
        layout = layout,
        current_page = 1,
        pager_text_format = "  Page %d of %d  ",
    }, self)

    local left_button   = Button:new(monitor, layout, {
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
    })
    local right_button  = Button:new(monitor, layout, {
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
    })

    result.left_button  = left_button
    result.right_button = right_button

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

function pager:handle_click(x, y)
    local handled = self.left_button:handle_click(x, y)

    if not handled then
        handled = self.right_button:handle_click(x, y)
    end

    return handled
end

function pager:total_width()
    return self.left_button.width + string.len(self.pager_text_format) + self.right_button.width
end

function pager:render(x, y)
    self.x = x
    self.y = y

    if not self.total_pages then
        error("Set total pages before rendering a pager.")
    elseif self.total_pages <= 1 then
        return
    end

    local pager_text = self.pager_text_format:format(self.current_page, self.total_pages)
    local text_width = string.len(pager_text)

    self.left_button:render(x, y)

    self.monitor.setCursorPos(x + self.left_button.width, y + 1)
    self.monitor.setBackgroundColour(self.layout.bg_colour)
    self.monitor.write(pager_text)

    self.right_button:render(x + self.left_button.width + text_width, y)
end

return pager
