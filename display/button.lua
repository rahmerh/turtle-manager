local button = {}
button.__index = button

function button:new(opts)
    assert(opts.x and
        opts.y and
        opts.width and
        opts.height and
        opts.text and
        opts.text_color and
        opts.button_color and
        opts.on_click, "Missing button config")
    return setmetatable({
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

function button:render(mon)
    mon.setBackgroundColor(self.button_color)
    for i = 0, self.height - 1 do
        mon.setCursorPos(self.x, self.y + i)
        mon.write(string.rep(" ", self.width))
    end

    local middle_y = self.y + math.floor((self.height - 1) / 2)

    local text_len = string.len(self.text)
    if text_len > self.width then
        error(("Text can't be langer than the button's width (%d)"):format(self.width))
    end

    local middle_x = self.x + (self.width / 2) - (text_len / 2)

    mon.setCursorPos(middle_x, middle_y)
    mon.setTextColor(self.text_color)
    mon.write(self.text)
end

return button
