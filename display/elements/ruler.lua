local ruler = {}
ruler.__index = ruler

function ruler:new(m)
    return setmetatable({
        m = m
    }, self)
end

function ruler:render()
    local width, height = self.m:get_monitor_size()

    -- Horizontal ruler at bottom
    for x = 0, width - 1 do
        if x % 2 == 0 then
            self.m:set_bg_colour(colours.black)
        else
            self.m:set_bg_colour(colours.yellow)
        end
        self.m:write_at(" ", x + 1, height)
    end

    -- Vertical ruler on the left
    for y = 1, height do
        if y % 2 == 0 then
            self.m:set_bg_colour(colours.black)
        else
            self.m:set_bg_colour(colours.yellow)
        end
        self.m:write_at(" ", 1, y)
    end
end

return ruler
