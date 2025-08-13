local toggle = {}
toggle.__index = toggle

function toggle.new(m, label, label_colours, initial_value, on_toggle)
    return setmetatable({
        m = m,
        label = label,
        size = {
            width = 10,
        },
        label_colours = label_colours,
        state = initial_value,
        on_toggle = on_toggle
    }, toggle)
end

function toggle:handle_click(x, y)
    if not self.x or not self.y then
        return false
    end

    local is_in_x = x >= self.x and x < self.x + self.size.width
    local is_in_y = y == self.y

    if is_in_x and is_in_y then
        self.state = not self.state
        self.on_toggle(self.state)

        return true
    else
        return false
    end
end

function toggle:render(x, y)
    local toggle_start_x = x + string.len(self.label) + 1 -- + 1 for padding

    self.x = toggle_start_x
    self.y = y

    self.m:set_fg_colour(self.label_colours.fg)
    self.m:set_bg_colour(self.label_colours.bg)
    self.m:write_at(self.label, x, y)

    -- True side
    if self.state then
        self.m:set_bg_colour(colours.green)
        self.m:set_fg_colour(colours.black)
    else
        self.m:set_bg_colour(colours.grey)
        self.m:set_fg_colour(colours.lightGrey)
    end
    self.m:write_at(string.rep(" ", self.size.width / 2), toggle_start_x, y)
    self.m:write_at("Yes", toggle_start_x + 1, y)

    -- False side
    if self.state then
        self.m:set_bg_colour(colours.grey)
        self.m:set_fg_colour(colours.lightGrey)
    else
        self.m:set_bg_colour(colours.red)
        self.m:set_fg_colour(colours.black)
    end
    local false_x = toggle_start_x + self.size.width / 2
    self.m:write_at(string.rep(" ", self.size.width / 2), false_x, y)
    self.m:write_at("No", false_x + 1, y)
end

return toggle
