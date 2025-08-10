local locator = require("movement.locator")

local errors = require("lib.errors")
local miner = require("lib.miner")

local mover = {}

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

local function parse_error(reason)
    if reason == "Out of fuel" then return errors.NO_FUEL end
    if reason == "Movement obstructed" then return errors.BLOCKED end
end

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

local function move_on_axis(axis, amount, dig, state)
    local current_direction = mover.determine_orientation()

    local direction
    if axis == "x" then
        direction = amount > 0 and "east" or "west"
    elseif axis == "z" then
        direction = amount > 0 and "south" or "north"
    elseif axis == "y" then
        direction = amount > 0 and "up" or "down"
    end

    if current_direction ~= direction and current_direction ~= "up" and current_direction ~= "down" then
        mover.turn_to_direction(direction)
    end

    for _ = 1, math.abs(amount) do
        local moved, err
        if direction == "up" then
            if dig then
                miner.mine_up()
            end

            state.handle_state()

            moved, err = mover.move_up()
        elseif direction == "down" then
            if dig then
                miner.mine_down()
            end

            state.handle_state()

            moved, err = mover.move_down()
        else
            if dig then
                miner.mine()
            end

            state.handle_state()

            moved, err = mover.move_forward()
        end

        if not moved and err == errors.NO_FUEL then
            return moved, err
        elseif not moved then
            return moved, errors.BLOCKED
        end
    end

    return true
end

mover.turn_left = function()
    local current_orientation, err = mover.determine_orientation()
    if not current_orientation and err then
        return current_orientation, err
    end

    turtle.turnLeft()
    turtle_state.orientation = LEFT_ROTATION[current_orientation]
end

mover.turn_right = function()
    local current_orientation, err = mover.determine_orientation()
    if not current_orientation and err then
        return current_orientation, err
    end

    turtle.turnRight()
    turtle_state.orientation = RIGHT_ROTATION[current_orientation]
end

mover.determine_orientation = function()
    if turtle_state.orientation then
        return turtle_state.orientation
    end

    local coordinates_1, err_1 = locator.get_current_coordinates(true)
    if not coordinates_1 then
        return coordinates_1, err_1
    end

    local moved, err = turtle.forward()
    err = parse_error(err)
    if not moved and err == errors.NO_FUEL then
        return moved, err
    end

    local unstuck_turns = 0
    while not moved do
        unstuck_turns = unstuck_turns + 1
        turtle.turnLeft()
        moved, err = turtle.forward()

        if unstuck_turns > 3 then
            local moved_up, up_err = turtle.up()
            up_err = parse_error(up_err)

            if not moved_up and up_err == errors.BLOCKED then
                return nil, "Unable to determine orientation"
            end

            unstuck_turns = 0
        end
    end

    local coordinates_2, err_2 = locator.get_current_coordinates(true)
    if not coordinates_2 then
        return coordinates_2, err_2
    end

    local moved_back, moved_back_err = turtle.back()
    if not moved_back and moved_back_err then
        return moved, err
    end

    locator.get_current_coordinates(true)

    local direction
    if coordinates_2.x > coordinates_1.x then
        direction = "east"
    elseif coordinates_2.x < coordinates_1.x then
        direction = "west"
    elseif coordinates_2.z > coordinates_1.z then
        direction = "south"
    elseif coordinates_2.z < coordinates_1.z then
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

mover.move_back = function()
    local ok, err = turtle.back()

    if not ok and err then
        err = parse_error(err)
    else
        local direction = mover.determine_orientation()
        locator.moved_in_direction(1, mover.opposite_orientation_of(direction))
    end

    return ok, err
end

mover.move_forward = function()
    local ok, err = turtle.forward()

    if not ok and err then
        err = parse_error(err)
    else
        local direction = mover.determine_orientation()
        locator.moved_in_direction(1, direction)
    end

    return ok, err
end

mover.move_up = function()
    local ok, err = turtle.up()

    if not ok and err then
        err = parse_error(err)
    else
        locator.moved_in_direction(1, "up")
    end

    return ok, err
end

mover.move_down = function()
    local ok, err = turtle.down()

    if not ok and err then
        err = parse_error(err)
    else
        locator.moved_in_direction(1, "down")
    end

    return ok, err
end

mover.move_to = function(x, y, z, dig, state)
    dig = dig or false

    local attempts = 0
    while attempts < 50 do
        local pos = locator.get_current_coordinates()

        if not pos then
            return nil, errors.NO_GPS
        end

        local delta = {
            x = x - pos.x,
            y = y - pos.y,
            z = z - pos.z
        }

        if delta.x == 0 and delta.y == 0 and delta.z == 0 then
            return true
        end

        local ordered_deltas = sort_axis(delta)

        local moved, err
        for i = 1, #ordered_deltas do
            local axis = ordered_deltas[i].axis
            local value = ordered_deltas[i].value

            if value ~= 0 then
                moved, err = move_on_axis(axis, value, dig, state)

                if err == errors.NO_FUEL then
                    return moved, err
                end
            end
        end

        -- Try some unstuck manouvers
        if not moved then
            local moved_up, moved_up_err
            while turtle.detect() do
                moved_up, moved_up_err = mover.move_up()

                if not moved_up and moved_up_err == errors.NO_FUEL then
                    return moved_up, moved_up_err
                end
            end

            -- It moved up, try to move forward to possibly change axis.
            if moved_up then
                local hopped, hopped_err = mover.move_forward()
                if not hopped and hopped_err == errors.NO_FUEL then
                    return hopped, hopped_err
                end
                attempts = 0
            end
        end

        if moved then
            attempts = 0
        else
            attempts = attempts + 1
        end
    end
end

return mover
