local printer = require("printer")
local locator = require("locator")
local fueler = require("fueler")

local mover = {}

local MAX_UNSTUCK_ATTEMPTS = 500

local LEFT_ROTATION = {
    north = "west",
    west = "south",
    south = "east",
    east = "north"
}

local RIGHT_ROTATION = {
    north = "east",
    east = "south",
    south = "west",
    west = "north"
}

local ORIENTATION_TO_DIRECTION_MAP = {
    north = { north = nil, east = "right", south = "around", west = "left" },
    east  = { north = "left", east = nil, south = "right", west = "around" },
    south = { north = "around", east = "left", south = nil, west = "right" },
    west  = { north = "right", east = "around", south = "left", west = nil },
}

local turtle_state = {}

local function sort_axis(delta)
    local list = {}
    for axis, value in pairs(delta) do
        table.insert(list, { axis = axis, value = value })
    end

    table.sort(list, function(a, b)
        return math.abs(a.value) > math.abs(b.value)
    end)

    return list
end

mover.turn_left = function()
    local current_orientation = mover.determine_orientation()
    turtle.turnLeft()
    turtle_state.orientation = LEFT_ROTATION[current_orientation]
end

mover.turn_right = function()
    local current_orientation = mover.determine_orientation()
    turtle.turnRight()
    turtle_state.orientation = RIGHT_ROTATION[current_orientation]
end

mover.determine_orientation = function()
    if turtle_state.orientation then
        return turtle_state.orientation
    end

    local x1, _, z1 = gps.locate(2)

    local unstuck_turns = 0
    while not mover.move_forward() do
        unstuck_turns = unstuck_turns + 1
        turtle.turnLeft() -- This has to be the native turtle turn, will cause recursion otherwise.

        if unstuck_turns > 3 then
            if not turtle.up() then
                turtle.down()
            end
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
    turtle_state.orientation = direction

    return direction
end

mover.opposite_orientation_of = function(orientation)
    return LEFT_ROTATION[LEFT_ROTATION[orientation]]
end

mover.turn_to_direction = function(target_direction)
    local current_orientation = mover.determine_orientation()
    if not current_orientation or current_orientation == target_direction then
        return
    end
    local turn = ORIENTATION_TO_DIRECTION_MAP[current_orientation][target_direction]

    if turn == "left" then
        mover.turn_left()
    elseif turn == "right" then
        mover.turn_right()
    elseif turn == "around" then
        if math.random(1, 2) == 1 then
            mover.turn_left()
            mover.turn_left()
        else
            mover.turn_right()
            mover.turn_right()
        end
    elseif turn == nil then
        return
    else
        error("Invalid turn direction: " .. tostring(turn))
    end

    turtle_state.orientation = target_direction
end

mover.move_forward = function()
    while not fueler.refuel() do
        printer.print_error("Could not refuel, sleeping for 10s...")
        os.sleep(10)
    end

    return turtle.forward()
end

mover.move_up = function()
    while not fueler.refuel() do
        printer.print_error("Could not refuel, sleeping for 10s...")
        os.sleep(10)
    end

    return turtle.up()
end

mover.move_down = function()
    while not fueler.refuel() do
        printer.print_error("Could not refuel, sleeping for 10s...")
        os.sleep(10)
    end

    return turtle.down()
end

mover.move_to_x = function(x, dig)
    dig = dig or false

    while not fueler.refuel() do
        printer.print_error("Could not refuel, sleeping for 10s...")
        os.sleep(10)
    end

    local pos = locator.get_pos()
    local delta = x - pos.x

    if delta == 0 then return end

    if delta > 0 then
        mover.turn_to_direction("east")
    else
        mover.turn_to_direction("west")
    end

    for _ = 1, math.abs(delta) do
        if dig then
            while turtle.detect() do
                turtle.dig()
            end
        end

        if not mover.move_forward() then
            printer.print_error("Got blocked while trying to move to X: " .. x)
            return
        end
    end
end

mover.move_to_y = function(y, dig)
    dig = dig or false

    while not fueler.refuel() do
        printer.print_error("Could not refuel, sleeping for 10s...")
        os.sleep(10)
    end

    local pos = locator.get_pos()
    local delta = y - pos.y

    if delta == 0 then return end

    for _ = 1, math.abs(delta) do
        local success = true

        if delta > 0 then
            if dig then
                while turtle.detectUp() do
                    turtle.digUp()
                end
            end

            success = mover.move_up()
        else
            if dig then
                while turtle.detectDown() do
                    turtle.digDown()
                end
            end

            success = mover.move_down()
        end

        if not success then
            printer.print_error("Got blocked while trying to move to Y: " .. y)
            return
        end
    end
end

mover.move_to_z = function(z, dig)
    dig = dig or false

    while not fueler.refuel() do
        printer.print_error("Could not refuel, sleeping for 10s...")
        os.sleep(10)
    end

    local pos = locator.get_pos()
    local delta = z - pos.z

    if delta == 0 then return end

    if delta > 0 then
        mover.turn_to_direction("south")
    else
        mover.turn_to_direction("north")
    end

    for _ = 1, math.abs(delta) do
        if not mover.move_forward() then
            printer.print_error("Got blocked while trying to move to Z: " .. z)
            return
        end
    end
end

mover.move_to = function(x, y, z)
    while true do
        if not fueler.refuel() then
            printer.print_error("Could not refuel, sleeping for 10s...")
            os.sleep(10)
            goto continue
        end
        local current_direction = mover.determine_orientation()

        local pos = locator.get_pos()
        local delta = {
            dx = x - pos.x,
            dy = y - pos.y,
            dz = z - pos.z
        }

        if delta.dx == 0 and delta.dy == 0 and delta.dz == 0 then
            return true
        end

        local ordered_deltas = sort_axis(delta)
        local axis = ordered_deltas[1].axis
        local value = ordered_deltas[1].value

        local direction
        if axis == "dx" then
            direction = value > 0 and "east" or "west"
        elseif axis == "dz" then
            direction = value > 0 and "south" or "north"
        elseif axis == "dy" then
            direction = value > 0 and "up" or "down"
        end

        while turtle_state.stuck do
            turtle_state.unstuck_attempt = 0

            local preferred_direction = direction
            while true do
                if turtle_state.unstuck_attempt > MAX_UNSTUCK_ATTEMPTS then
                    error("Turtle is stuck and can't get out, please help.")
                end

                turtle_state.unstuck_attempt = turtle_state.unstuck_attempt + 1

                -- Try some common ways to either duck or climb over stuff
                if turtle.detect() and turtle.detectDown() and not turtle.detectUp() then
                    while turtle.detect() and not turtle.detectUp() do
                        turtle.up()
                        mover.move_forward()
                    end
                    turtle_state.stuck = false
                    break
                end

                -- Scan for non blocking paths
                local blocking_blocks = {}
                for _ = 1, 4 do
                    if turtle.detect() then
                        blocking_blocks[turtle_state.orientation] = true
                    end
                    mover.turn_left()
                end

                local left_rotation = LEFT_ROTATION[preferred_direction]
                local right_rotation = RIGHT_ROTATION[preferred_direction]
                local amount_of_steps = math.random(1, 5)
                if not blocking_blocks[left_rotation] then
                    mover.turn_to_direction(left_rotation)
                    for _ = 1, amount_of_steps do
                        mover.move_forward()
                    end
                    turtle_state.stuck = false
                    break
                elseif not blocking_blocks[right_rotation] then
                    mover.turn_to_direction(right_rotation)
                    for _ = 1, amount_of_steps do
                        mover.move_forward()
                    end
                    turtle_state.stuck = false
                    break
                end
            end
        end

        if current_direction ~= direction and current_direction ~= "up" and current_direction ~= "down" then
            mover.turn_to_direction(direction)
        end

        for _ = 1, math.abs(value) do
            if direction == "up" then
                if not turtle.up() then
                    if turtle.detectUp() then
                        turtle_state.stuck = true
                    end
                    break
                end
            elseif direction == "down" then
                if not turtle.down() then
                    if turtle.detectDown() then
                        turtle_state.stuck = true
                    end
                    break
                end
            elseif not mover.move_forward() then
                if turtle.detect() then
                    turtle_state.stuck = true
                end
                break
            end
        end
        ::continue::
    end
end

return mover
