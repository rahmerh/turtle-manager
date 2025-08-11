local text = {}
text.__index = text

function text:new(m, content, text_colour, bg_colour)
    return setmetatable({
        m = m,
        content = content,
        colour = text_colour,
        bg_colour = bg_colour
    }, self)
end

function text:render(x, y)
    if self.bg_colour then
        self.m:set_bg_colour(self.bg_colour)
    end
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
