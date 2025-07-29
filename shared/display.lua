local MAX_WIDTH = 30

local display = {}

local monitor = peripheral.find("monitor")
if not monitor then error("No monitor found") end

monitor.setTextScale(0.5)

local function clear()
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

local function next_line(x, amount)
    amount = amount or 1
    x = x or 1

    local _, y = monitor.getCursorPos()
    monitor.setCursorPos(x, y + amount)
end

function display.display_block(id, lines, bg_colour, fg_colour)
    bg_colour = bg_colour or colours.white
    fg_colour = fg_colour or colours.black

    local prev_bg_colour = monitor.getBackgroundColour()
    local prev_fg_colour = monitor.getTextColour()

    monitor.setBackgroundColour(bg_colour)
    monitor.setTextColour(fg_colour)

    local start_x, start_y = monitor.getCursorPos()

    monitor.write(string.rep(" ", MAX_WIDTH))
    next_line()
    for i = 1, #lines do
        local line = "  " .. lines[i]

        if #line > MAX_WIDTH then
            -- TODO: Truncate
            error("Can't display lines longer than " .. MAX_WIDTH .. " characters.")
        end

        local padded = line .. string.rep(" ", MAX_WIDTH - #line)
        monitor.write(padded)
        next_line()
    end
    monitor.write(string.rep(" ", MAX_WIDTH))

    local end_x, end_y = monitor.getCursorPos()

    monitor.setBackgroundColour(prev_bg_colour)
    monitor.setTextColour(prev_fg_colour)

    display.blocks[id] = {
        start_x = start_x,
        start_y = start_y,
        end_x = end_x,
        end_y = end_y
    }
end

function display.turtles(turtles)
    clear()
    for id, data in pairs(turtles) do
        local lines = {
            ("ID: %s (%s)"):format(id, data.role),
            ("Status: %s"):format(data.status),
            ("Mining layer %d of %d"):format(data.current_layer, data.total_layers),
            ("Last seen at: %s"):format(os.date("%H:%M:%S", data.last_seen))
        }
        display.display_block(id, lines, colours.white, colours.black)
        next_line(_, 2)
    end
end

return display
