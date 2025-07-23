local printer = require("printer")

local mover = {}

local TURN_MAP = {
    north = { north = nil, east = "right", south = "around", west = "left" },
    east  = { north = "left", east = nil, south = "right", west = "around" },
    south = { north = "around", east = "left", south = nil, west = "right" },
    west  = { north = "right", east = "around", south = "left", west = nil },
}

local turtle_state = {}

local function refuel()
    if turtle.getFuelLevel() > 0 then return true end

    turtle.select(1)
    if turtle.refuel(1) then return true end
    for slot = 2, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            turtle.transferTo(1)
        end
    end
    turtle.select(1)
    return turtle.refuel(1)
end

local function get_pos()
    local x, y, z = gps.locate(2)
    if not x then error("GPS failed") end
    return { x = x, y = y, z = z }
end

local function determine_direction()
    if turtle_state.dir then
        return turtle_state.dir
    end

    local x1, _, z1 = gps.locate(2)

    local unstuck_turns = 0
    while not turtle.forward() do
        unstuck_turns = unstuck_turns + 1
        turtle.turnLeft()

        if unstuck_turns > 3 then
            if not turtle.up() then
                turtle.down()
            end
            unstuck_turns = 0
        end
    end

    local x2, _, z2 = gps.locate(2)

    turtle.back()

    local direction
    if x2 > x1 then
        direction = "east"
    elseif x2 < x1 then
        direction = "west"
    elseif z2 > z1 then
        direction = "south"
    elseif z2 < z1 then
        direction = "north"
    else
        direction = "unknown"
    end
    turtle_state.dir = direction

    return direction
end

local function face_dir(current, target)
    local turn = TURN_MAP[current][target]

    if not turn then return end

    if turn == "left" then
        turtle.turnLeft()
    elseif turn == "right" then
        turtle.turnRight()
    elseif turn == "around" then
        turtle.turnLeft()
        turtle.turnLeft()
    else
        error("Invalid turn direction: " .. tostring(turn))
    end

    turtle_state.dir = target

    return target
end

local function try_step(direction)
    if direction == "up" then
        return turtle.up()
    elseif direction == "down" then
        return turtle.down()
    else
        return turtle.forward()
    end
end

local function get_sorted_deltas(delta)
    local list = {}
    for axis, value in pairs(delta) do
        table.insert(list, { axis = axis, value = value })
    end

    table.sort(list, function(a, b)
        return math.abs(a.value) > math.abs(b.value)
    end)

    return list
end

local function delta_to_direction(axis, value)
    if axis == "dx" then
        return value > 0 and "east" or "west"
    elseif axis == "dz" then
        return value > 0 and "south" or "north"
    elseif axis == "dy" then
        return value > 0 and "up" or "down"
    else
        error("Invalid axis: " .. tostring(axis))
    end
end

local function determine_new_direction_to_turn_left(current)
    for k, v in pairs(TURN_MAP[current]) do
        if v == "left" then
            return k
        end
    end
    return nil
end

mover.move_to = function(x, y, z)
    printer.print_info("Moving to X: " .. x .. " Y: " .. y .. " Z: " .. z)

    local last_axis
    while true do
        if not refuel() then
            printer.print_error("Could not refuel, sleeping for 10s...")
            os.sleep(10)
            goto continue
        end

        local current_direction = determine_direction()

        local pos = get_pos()
        local delta = {
            dx = x - pos.x,
            dy = y - pos.y,
            dz = z - pos.z
        }

        if delta.dx == 0 and delta.dy == 0 and delta.dz == 0 then
            face_dir(current_direction, "north")
            break
        end

        local ordered_deltas = get_sorted_deltas(delta)
        local axis = ordered_deltas[1].axis
        local value = ordered_deltas[1].value
        local direction = delta_to_direction(axis, value)

        -- Turtle is stuck, try to go up or back to get out of whatever is blocking it.
        if last_axis == axis and not try_step("up") then
            if not turtle.back() then
                local new_direction = determine_new_direction_to_turn_left(current_direction)
                face_dir(current_direction, new_direction)
            end
            goto continue
        end

        last_axis = axis

        if current_direction ~= direction and current_direction ~= "up" and current_direction ~= "down" then
            face_dir(current_direction, direction)
        end

        for _ = 1, math.abs(value) do
            local ok = try_step(direction)
            if not ok then
                printer.print_warning("Blocked while moving " .. direction)
                break
            end
        end
        ::continue::
    end

    printer.print_success("Arrived at destination.")
end

return mover
