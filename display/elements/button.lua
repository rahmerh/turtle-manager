local button = {}
button.__index = button

function button:new(m, opts)
    local required_fields = {
        "size", "text", "text_color", "button_color", "on_click"
    }

    for _, field in ipairs(required_fields) do
        if opts[field] == nil then
            error("Missing button config: '" .. field .. "' is required", 2)
        end
    end

    return setmetatable({
        m = m,
        size = opts.size,
        text = opts.text,
        button_color = opts.button_color,
        text_color = opts.text_color,
        on_click = opts.on_click
    }, self)
end

function button:is_clicked(x, y)
    return x >= self.x and x < self.x + self.size.width
        and y >= self.y and y < self.y + self.size.height
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

function button:render(x, y)
    self.x = x
    self.y = y

    self.m:set_bg_colour(self.button_color)
    for i = 0, self.size.height - 1 do
        self.m:write_at(string.rep(" ", self.size.width), x, y + i)
    end

    local middle_y = y + math.floor((self.size.height - 1) / 2)

    if self.size.height % 2 == 0 then
        middle_y = middle_y + 1
    end

    self.m:set_fg_colour(self.text_color)
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
end

return button
