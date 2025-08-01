local time = require("shared.time")
local errors = require("shared.errors")

local miner = {}

local FORBIDDEN = {
    ["minecraft:bedrock"] = true,
    ["minecraft:end_portal"] = true,
    ["minecraft:end_portal_frame"] = true,
    ["minecraft:barrier"] = true,
}

local TURTLES = {
    ["computercraft:turtle_advanced"] = true,
    ["computercraft:turtle_normal"] = true,
}

local function inspect_direction(direction)
    local ok, metadata
    if direction == "forward" then
        ok, metadata = turtle.inspect()
    elseif direction == "up" then
        ok, metadata = turtle.inspectUp()
    elseif direction == "down" then
        ok, metadata = turtle.inspectDown()
    else
        ok = nil
        metadata = errors.INVALID_DIRECTION
    end

    return ok, metadata
end

local function detect_direction(direction)
    local ok, err
    if direction == "forward" then
        ok = turtle.detect()
    elseif direction == "up" then
        ok = turtle.detectUp()
    elseif direction == "down" then
        ok = turtle.detectDown()
    else
        ok = nil
        err = errors.INVALID_DIRECTION
    end

    return ok, err
end

local function dig_direction(direction)
    local ok, err
    if direction == "forward" then
        ok, err = turtle.dig()
    elseif direction == "up" then
        ok, err = turtle.digUp()
    elseif direction == "down" then
        ok, err = turtle.digDown()
    else
        ok = nil
        err = errors.INVALID_DIRECTION
    end

    return ok, err
end

local function mine_direction(direction)
    local ok, metadata = inspect_direction(direction)

    if not ok then
        return true
    end

    local deadline = time.alive_duration_in_seconds() + 5
    while TURTLES[metadata.name] do
        sleep(1)
        ok, metadata = inspect_direction(direction)

        local now = time.alive_duration_in_seconds()

        if now > deadline then
            return nil, errors.BLOCKED
        end
    end

    if FORBIDDEN[metadata.name] then
        return nil, errors.BLOCKED
    end

    while detect_direction(direction) do
        dig_direction(direction)
    end

    return true
end

function miner.mine()
    return mine_direction("forward")
end

function miner.mine_up()
    return mine_direction("up")
end

function miner.mine_down()
    return mine_direction("down")
end

return miner
