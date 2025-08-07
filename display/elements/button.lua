local button = {}
button.__index = button

function button:new(monitor, opts)
    local required_fields = {
        "x", "y", "width", "height", "text", "text_color", "button_color", "on_click"
    }

    for _, field in ipairs(required_fields) do
        if opts[field] == nil then
            error("Missing button config: '" .. field .. "' is required", 2)
        end
    end

    return setmetatable({
        monitor = monitor,
        x = opts.x,
        y = opts.y,
        width = opts.width,
        height = opts.height,
        text = opts.text,
        button_color = opts.button_color,
        text_color = opts.text_color,
        on_click = opts.on_click
    }, self)
end

function button:is_clicked(x, y)
    return x >= self.x and x < self.x + self.width
        and y >= self.y and y < self.y + self.height
end

function button:handle_click(x, y)
    if self:is_clicked(x, y) and self.on_click then
        self.on_click()
        return true
    end

    return false
end

function button:render()
    self.monitor.setBackgroundColor(self.button_color)
    for i = 0, self.height - 1 do
        self.monitor.setCursorPos(self.x, self.y + i)
        self.monitor.write(string.rep(" ", self.width))
    end

    local middle_y = self.y + math.floor((self.height - 1) / 2)

    if self.height % 2 == 0 then
        middle_y = middle_y + 1
    end

    local text_len = string.len(self.text)
    if text_len > self.width then
        error(("Text can't be langer than the button's width (%d)"):format(self.width))
    end

    local middle_x = self.x + (self.width / 2) - (text_len / 2)

    self.monitor.setCursorPos(middle_x, middle_y)
    self.monitor.setTextColor(self.text_color)
    self.monitor.write(self.text)
end

return button
