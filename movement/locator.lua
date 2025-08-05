local time = require("lib.time")
local printer = require("lib.printer")
local errors = require("lib.errors")

local locator = {}

local DIRECTION_VECTORS = {
    north = { x = 0, y = 0, z = -1 },
    south = { x = 0, y = 0, z = 1 },
    east  = { x = 1, y = 0, z = 0 },
    west  = { x = -1, y = 0, z = 0 },
    up    = { x = 0, y = 1, z = 0 },
    down  = { x = 0, y = -1, z = 0 },
}

local function get_coordinates_from_gps()
    local deadline = time.alive_duration_in_seconds() + 10

    local coordinates
    while true do
        local now = time.alive_duration_in_seconds()

        if now > deadline then
            break
        end

        local x, y, z = gps.locate(2)

        if x and y and z then
            coordinates = {
                x = x,
                y = y,
                z = z
            }

            break
        end

        printer.print_warning("Waiting for gps...")
    end

    return coordinates
end

local function ensure_coordinates(force_refresh)
    if not force_refresh and locator.coordinates then
        return true
    end

    locator.coordinates = get_coordinates_from_gps()

    return locator.coordinates ~= nil
end

function locator.moved_in_direction(amount, direction)
    if not ensure_coordinates() then
        return nil, errors.NO_GPS
    end

    local delta = DIRECTION_VECTORS[direction]

    if not delta then
        return nil, errors.INVALID_DIRECTION .. ": " .. direction
    end

    locator.coordinates.x = locator.coordinates.x + (delta.x * amount)
    locator.coordinates.y = locator.coordinates.y + (delta.y * amount)
    locator.coordinates.z = locator.coordinates.z + (delta.z * amount)

    return true
end

function locator.get_current_coordinates(force_refresh)
    force_refresh = force_refresh or false

    if not ensure_coordinates(force_refresh) then
        return nil, errors.NO_GPS
    end

    return {
        x = locator.coordinates.x,
        y = locator.coordinates.y,
        z = locator.coordinates.z
    }
end

return locator
