local Button = require("display.elements.button")

local pager = {}
pager.__index = pager

function pager:new(m)
    local result        = setmetatable({
        m = m,
        current_page = 1,
        pager_text_format = "  Page %d of %d  ",
    }, self)

    local left_button   = Button:new(m, {
            width = 5,
            height = 2,
        },
        "<",
        colours.white,
        colours.grey,
        function()
            if result.current_page > 1 then
                result.current_page = result.current_page - 1
            end
        end)

    local right_button  = Button:new(m, {
            width = 5,
            height = 2,
        },
        ">",
        colours.white,
        colours.grey,
        function()
            if result.current_page < result.total_pages then
                result.current_page = result.current_page + 1
            end
        end)

    result.left_button  = left_button
    result.right_button = right_button

    return result
end

function pager:set_total_pages(total_pages)
    self.total_pages = total_pages
end

function pager:handle_click(x, y)
    local handled = self.left_button:handle_click(x, y)

    if not handled then
        handled = self.right_button:handle_click(x, y)
    end

    return handled
end

function pager:total_width()
    return self.left_button.size.width + string.len(self.pager_text_format) + self.right_button.size.width
end

function pager:render(x, y)
    if not self.total_pages then
        error("Set total pages before rendering a pager.")
    elseif self.total_pages <= 1 then
        return
    end

    local pager_text = self.pager_text_format:format(self.current_page, self.total_pages)
    local text_width = string.len(pager_text)

    self.left_button:render(x, y)
    self.m:set_bg_colour(self.m:get_default_bg_colour())
    self.m:write_at(pager_text, x + self.left_button.size.width, y + 1)
    self.right_button:render(x + self.left_button.size.width + text_width, y)
end

return pager
