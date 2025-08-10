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
        y_offset = nil,
        target_y = nil,
        state = "enter"
    })
end

function Notifier:has_notifications()
    return #self.items > 0
end

function Notifier:is_animating()
    for _, item in ipairs(self.items) do
        if item.state ~= "hold" then
            return true
        end
    end
    return false
end

function Notifier:update(now)
    local width, _ = self.m:get_monitor_size()
    now = now or os.clock()

    local y = 1
    for _, n in ipairs(self.items) do
        n.target_y = y
        if n.y_offset == nil then n.y_offset = y end
        y = y + 4
    end

    for i = #self.items, 1, -1 do
        local n = self.items[i]
        local elapsed = now - n.start_time
        local text_width = #n.text + 4
        local final_x = width - text_width

        local slide_in_time, slide_out_time = 1, 1

        if n.state == "enter" then
            local progress = math.min(elapsed / slide_in_time, 1)
            n.x_offset = math.floor(width - progress * text_width)
            if progress >= 1 then
                n.state = "hold"
                n.start_time = now
                n.x_offset = final_x
            end
        elseif n.state == "hold" then
            n.x_offset = final_x
            if elapsed >= n.duration then
                n.state = "exit"
                n.start_time = now
            end
        elseif n.state == "exit" then
            local p = math.min(elapsed / slide_out_time, 1)
            n.x_offset = math.floor(final_x + p * (text_width + 2))
            if p >= 1 then
                table.remove(self.items, i)
                goto continue
            end
        end

        if n.state == "hold" or n.state == "shift" then
            local vertical_speed = 2
            local dy = n.target_y - n.y_offset
            if dy ~= 0 then
                n.state = "shift"
                if dy > 0 then
                    n.y_offset = n.y_offset + math.min(dy, vertical_speed)
                else
                    n.y_offset = n.y_offset + math.max(dy, -vertical_speed)
                end
            elseif n.state == "shift" then
                n.state = "hold"
            end
        end

        ::continue::
    end
end

function Notifier:render()
    for _, n in ipairs(self.items) do
        self.m:set_bg_colour(colours.blue)
        self.m:set_fg_colour(colours.black)

        local notification_text = " " .. n.text .. " "

        self.m:write_at(string.rep(" ", #notification_text), n.x_offset, n.y_offset + 1)
        self.m:write_at(notification_text, n.x_offset, n.y_offset + 2)
        self.m:write_at(string.rep(" ", #notification_text), n.x_offset, n.y_offset + 3)
    end
end

return Notifier
