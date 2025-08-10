local Notifier = {}
Notifier.__index = Notifier

function Notifier:new(m)
    return setmetatable({
        m = m,
        items = {}
    }, self)
end

function Notifier:add_notification(text, duration)
    table.insert(self.items, {
        text = text,
        duration = duration or 3,
        start_time = os.clock(),
        x_offset = nil,
        state = "enter"
    })
end

function Notifier:has_notifications()
    return #self.items > 0
end

function Notifier:is_animating()
    for _, item in ipairs(self.items) do
        if item.state == "enter" then
            return true
        end
    end

    return false
end

function Notifier:update(now)
    local width, _ = self.m:get_monitor_size()

    for i = #self.items, 1, -1 do
        local n = self.items[i]
        local elapsed = now - n.start_time

        if n.state == "enter" then
            local slide_time = 1
            local progress = math.min(elapsed / slide_time, 1)
            local text_width = #n.text + 4
            n.x_offset = math.floor(width - progress * text_width)

            if progress >= 1 then
                n.state = "hold"
                n.start_time = now
            end
        elseif n.state == "hold" then
            n.x_offset = width - (#n.text + 4)
            if elapsed >= n.duration then
                table.remove(self.items, i)
            end
        end
    end
end

function Notifier:render()
    local y = 1

    for _, n in ipairs(self.items) do
        self.m:set_bg_colour(colours.blue)
        self.m:set_fg_colour(colours.black)

        local notification_text = " " .. n.text .. " "

        self.m:write_at(string.rep(" ", #notification_text), n.x_offset, y + 1)
        self.m:write_at(notification_text, n.x_offset, y + 2)
        self.m:write_at(string.rep(" ", #notification_text), n.x_offset, y + 3)

        y = y + 4
    end
end

return Notifier
