local printer = require("printer")
local locator = require("locator")

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

local function turn_left()
    local current_orientation = mover.determine_orientation()
    turtle.turnLeft()
    turtle_state.orientation = LEFT_ROTATION[current_orientation]
end

local function turn_right()
    local current_orientation = mover.determine_orientation()
    turtle.turnRight()
    turtle_state.orientation = RIGHT_ROTATION[current_orientation]
end

mover.refuel = function()
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

mover.determine_orientation = function()
    if turtle_state.orientation then
        return turtle_state.orientation
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
    mover.turn_to_direction(direction)

    return direction
end

mover.turn_to_direction = function(target_direction)
    local current_orientation = mover.determine_orientation()
    if not current_orientation or current_orientation == target_direction then
        return
    end
    local turn = ORIENTATION_TO_DIRECTION_MAP[current_orientation][target_direction]

    if turn == "left" then
        turn_left()
    elseif turn == "right" then
        turn_right()
    elseif turn == "around" then
        if math.random(1, 2) == 1 then
            turn_left()
            turn_left()
        else
            turn_right()
            turn_right()
        end
    elseif turn == nil then
        return
    else
        error("Invalid turn direction: " .. tostring(turn))
    end

    turtle_state.orientation = target_direction
end

mover.move_to = function(x, y, z)
    while true do
        if not mover.refuel() then
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

        if turtle_state.stuck then
            turtle_state.unstuck_attempt = 0

            local preferred_direction = direction
            while true do
                turtle_state.unstuck_attempt = turtle_state.unstuck_attempt + 1

                if turtle.detect() and turtle.detectDown() and not turtle.detectUp() then
                    while turtle.detect() and not turtle.detectUp() do
                        turtle.up()
                        turtle.forward()
                    end
                    turtle_state.stuck = false
                    turtle_state.unstuck_attempt = 0
                    goto continue
                end

                local blocking_blocks = {}
                for _ = 1, 4 do
                    if turtle.detect() then
                        blocking_blocks[turtle_state.orientation] = true
                    end
                    turn_left()
                end

                local left_rotation = LEFT_ROTATION[preferred_direction]
                local right_rotation = RIGHT_ROTATION[preferred_direction]
                local amount_of_steps = math.random(1, 5)
                if not blocking_blocks[left_rotation] then
                    mover.turn_to_direction(left_rotation)
                    for _ = 1, amount_of_steps do
                        turtle.forward()
                    end
                    turtle_state.stuck = false
                    turtle_state.unstuck_attempt = 0
                    goto continue
                elseif not blocking_blocks[right_rotation] then
                    mover.turn_to_direction(right_rotation)
                    for _ = 1, amount_of_steps do
                        turtle.forward()
                    end
                    turtle_state.stuck = false
                    turtle_state.unstuck_attempt = 0
                    goto continue
                end

                if turtle_state.unstuck_attempt > MAX_UNSTUCK_ATTEMPTS then
                    error("Turtle is stuck and can't get out, please help.")
                end
            end

            turtle_state.stuck = false
            turtle_state.unstuck_attempt = 0
        end

        if current_direction ~= direction and current_direction ~= "up" and current_direction ~= "down" then
            mover.turn_to_direction(direction)
        end

        for _ = 1, math.abs(value) do
            if direction == "up" then
                turtle.up()
            elseif direction == "down" then
                turtle.down()
            elseif not turtle.forward() then
                turtle_state.stuck = true
                break
            end
        end
        ::continue::
    end
end

return mover
