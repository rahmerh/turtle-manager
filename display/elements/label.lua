local validator = require("lib.validator")

local label = {}
label.__index = label

function label:new(m, size, text, label_colour, text_colour, truncate_text)
    validator.validate_parameter(size, "table", true, "size")
    validator.validate_parameter(text, "string", true, "text")
    validator.validate_parameter(label_colour, "number", true, "label_colour")
    validator.validate_parameter(text_colour, "number", true, "text_colour")
    validator.validate_parameter(truncate_text, "boolean", false, "truncate_text")

    truncate_text = truncate_text or false

    return setmetatable({
        m = m,
        size = size,
        text = text,
        truncate_text = truncate_text,
        label_colour = label_colour,
        text_colour = text_colour,
    }, self)
end

function label:render(x, y)
    self.m:set_bg_colour(self.label_colour)
    for i = 0, self.size.height - 1 do
        self.m:write_at(string.rep(" ", self.size.width), x, y + i)
    end

    local middle_y = y + math.floor((self.size.height - 1) / 2)

    if self.size.height % 2 == 0 then
        middle_y = middle_y + 1
    end


    self.m:set_fg_colour(self.text_colour)
    if type(self.text) == "string" then
        local to_render
        if string.len(self.text) > self.size.width and self.truncate_text then
            to_render = string.sub(self.text, 1, self.size.width - 3) .. "..."
        else
            to_render = self.text
        end

        local middle_x = x + (self.size.width / 2) - (string.len(to_render) / 2)

        self.m:write_at(to_render, middle_x, middle_y)
    elseif type(self.text) == "table" then
        for i = 1, #self.text do
            local middle_x = self.m.center_x_within(string.len(self.text[i]), self.size.width)
            self.m:write_at(self.text[i], x + middle_x, y + i)
        end
    end
end

return label
