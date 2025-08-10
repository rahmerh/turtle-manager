local validator = require("lib.validator")

local button = {}
button.__index = button

function button:new(m, size, text, text_colour, button_colour, on_click)
    validator.validate_parameter(size, "table", true, "size")
    validator.validate_parameter(text_colour, "number", true, "text_colour")
    validator.validate_parameter(button_colour, "number", true, "button_colour")
    validator.validate_parameter(on_click, "function", true, "on_click")

    return setmetatable({
        m = m,
        size = size,
        text = text,
        button_colour = button_colour,
        text_colour = text_colour,
        on_click = on_click,
        is_selected = false
    }, self)
end

function button:is_clicked(x, y)
    if not self.x or not self.y then
        return false
    end

    local is_in_x = x >= self.x and x < self.x + self.size.width
    local is_in_y = y >= self.y and y < self.y + self.size.height

    return is_in_x and is_in_y
end

function button:handle_click(x, y)
    if not x or not y then
        error("Both x and y required.")
    end

    if self:is_clicked(x, y) and self.on_click then
        self.on_click()
        return true
    end

    return false
end

function button:select()
    self.is_selected = true
end

function button:unselect()
    self.is_selected = false
end

function button:render(x, y)
    self.x = x
    self.y = y

    local initial_bg_color = self.m:get_bg_colour()
    local initial_fg_color = self.m:get_fg_colour()

    self.m:set_bg_colour(self.button_colour)
    for i = 0, self.size.height - 1 do
        self.m:write_at(string.rep(" ", self.size.width), x, y + i)
    end

    if self.is_selected then
        self.m:set_fg_colour(colours.black)
        self.m:write_at(string.rep("-", self.size.width), x, self.size.height)
        self.m:set_fg_colour(initial_fg_color)
    end

    local middle_y = y + math.floor((self.size.height - 1) / 2)

    if self.size.height % 2 == 0 then
        middle_y = middle_y + 1
    end

    self.m:set_fg_colour(self.text_colour)
    if type(self.text) == "string" then
        local text_len = string.len(self.text)
        if text_len > self.size.width then
            error(("Text can't be langer than the button's width (%d)"):format(self.size.width))
        end

        local middle_x = x + (self.size.width / 2) - (text_len / 2)

        self.m:write_at(self.text, middle_x, middle_y)
    elseif type(self.text) == "table" then
        for i = 1, #self.text do
            local middle_x = self.m.center_x_within(string.len(self.text[i]), self.size.width)
            self.m:write_at(self.text[i], x + middle_x, y + i)
        end
    end
    self.m:set_fg_colour(initial_fg_color)
    self.m:set_bg_colour(initial_bg_color)
end

return button
