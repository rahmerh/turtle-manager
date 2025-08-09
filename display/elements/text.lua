local text = {}
text.__index = text

function text:new(m, content, colour)
    return setmetatable({
        m = m,
        content = content,
        colour = colour
    }, self)
end

function text:render(x, y)
    self.m:set_fg_colour(self.colour)
    if type(self.content) == "string" then
        self.m:write_at(self.content, x, y)
    elseif type(self.content) == "table" then
        for i = 1, #self.content do
            self.m:write_at(self.content[i], x, y + i)
        end
    end
end

return text
