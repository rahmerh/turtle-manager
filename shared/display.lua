local MAX_WIDTH = 30

local display = {
    display_order = {},
    blocks = {}
}

local monitor = peripheral.find("monitor")
if not monitor then error("No monitor found") end

local width, height = monitor.getSize()
display.size = {
    width = width,
    height = height
}

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

local function get_block_pos(id)
    local x = 1
    local y = 1
    local col_height = 0

    for _, block_id in ipairs(display.display_order) do
        local block = display.blocks[block_id]
        local block_height = #block.lines + 3

        -- If this block doesn't fit in current column
        if col_height + block_height > display.size.height then
            -- Move to next column
            x = x + MAX_WIDTH + 2
            y = 1
            col_height = 0
        end

        if block_id == id then
            return x, y
        end

        -- Prepare y for the next block
        y = y + block_height
        col_height = col_height + block_height
    end
end

local function write_block(lines, bg_colour, fg_colour)
    bg_colour = bg_colour or colours.white
    fg_colour = fg_colour or colours.black

    local prev_bg_colour = monitor.getBackgroundColour()
    local prev_fg_colour = monitor.getTextColour()

    monitor.setBackgroundColour(bg_colour)
    monitor.setTextColour(fg_colour)

    local x, _ = monitor.getCursorPos()
    monitor.write(string.rep(" ", MAX_WIDTH))
    next_line(x)
    for i = 1, #lines do
        local line = "  " .. lines[i]

        if #line > MAX_WIDTH then
            -- TODO: Truncate
            error("Can't display lines longer than " .. MAX_WIDTH .. " characters.")
        end

        local padded = line .. string.rep(" ", MAX_WIDTH - #line)
        monitor.write(padded)
        next_line(x)
    end
    monitor.write(string.rep(" ", MAX_WIDTH))

    monitor.setBackgroundColour(prev_bg_colour)
    monitor.setTextColour(prev_fg_colour)
end

function display.add_or_update_block(id, lines)
    if not display.blocks[id] then
        table.insert(display.display_order, id)
    end
    display.blocks[id] = {
        lines = lines
    }
end

function display.remove_block(id)
    display.blocks[id] = nil

    for i = #display.display_order, 1, -1 do
        if display.display_order[i] == id then
            table.remove(display.display_order, i)
            break
        end
    end
end

function display.render()
    clear()
    for i = 1, #display.display_order do
        local id_to_display = display.display_order[i]
        local block = display.blocks[id_to_display]

        local x, y = get_block_pos(id_to_display)
        if x and y then
            monitor.setCursorPos(x, y)
            write_block(block.lines)
        end
    end
end

function display.status_lines_for(turtle)
    local lines
    if turtle.role == "quarry" then
        lines = {
            ("ID: %s (%s)"):format(turtle.id, turtle.role),
            ("Status: %s"):format(turtle.status),
            ("Mining layer %d of %d"):format(turtle.current_layer, turtle.total_layers),
            ("Last seen at: %s"):format(os.date("%H:%M:%S", turtle.last_seen))
        }
    elseif turtle.role == "runner" then
        lines = {
            ("ID: %s (%s)"):format(turtle.id, turtle.role),
            ("Status: %s"):format(turtle.status),
            ("Queued tasks: %s"):format(turtle.queued_tasks),
            ("Last seen at: %s"):format(os.date("%H:%M:%S", turtle.last_seen))
        }
    end

    return lines
end

return display
