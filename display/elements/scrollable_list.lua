local scrollable_list = {}
scrollable_list.__index = scrollable_list

function scrollable_list:new(m, size, items)
    return setmetatable({
        m = m,
        size = size,
        items = items
    }, self)
end

function scrollable_list:render(x, y)
    self.m:set_bg_colour(colours.white)

    local list_x = x + 1
    local list_y = y

    local item_height = 5
    local spacing = 1
    for _, item in ipairs(self.items) do
        for i = 0, item_height - 1 do
            self.m:write_at(string.rep(" ", self.size.width - 4), list_x, list_y + i)
        end

        list_y = list_y + item_height + spacing
    end
end

return scrollable_list
