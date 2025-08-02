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

    monitor.setBackgroundColour(colours.black)
    monitor.setTextColour(colours.white)
end

function display.add_or_update_block(id, lines, block_type)
    if not display.blocks[id] then
        table.insert(display.display_order, id)
    end

    local background_color
    if block_type == "normal" then
        background_color = colours.white
    elseif block_type == "warn" then
        background_color = colours.yellow
    elseif block_type == "err" then
        background_color = colours.red
    else
        error("Unknown block type: " .. block_type)
    end

    display.blocks[id] = {
        lines = lines,
        background_color = background_color
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
            write_block(block.lines, block.background_color)
        end
    end
end

function display.status_lines_for(id, turtle)
    local lines
    if turtle.role == "quarry" then
        lines = {
            ("ID: %s (%s)"):format(id, turtle.role),
            ("Status: %s"):format(turtle.metadata.status),
            ("Layer: %d Row: %d"):format(turtle.metadata.current_layer + 1, turtle.metadata.current_row + 1),
            ("Last seen at: %s"):format(os.date("%H:%M:%S", turtle.last_seen))
        }
    elseif turtle.role == "runner" then
        local runner_is_running = string.find(turtle.metadata.status, "Running", 1, true)
        lines = {
            ("ID: %s (%s)"):format(id, turtle.role),
            ("Status: %s"):format(turtle.metadata.status),
            ("Tasks: %d out of %s"):format((runner_is_running) and 1 or 0, turtle.metadata.queued_tasks),
            ("Last seen at: %s"):format(os.date("%H:%M:%S", turtle.last_seen))
        }
    end

    return lines
end

return display
