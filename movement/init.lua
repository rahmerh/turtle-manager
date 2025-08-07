local mover = require("movement.mover")
local fueler = require("movement.fueler")
local locator = require("movement.locator")

local errors = require("lib.errors")

local M = {}

function M.move_to(x, y, z, ctx)
    local retries = (ctx and ctx.retries) or 5
    local dig = (ctx and ctx.dig) or false

    local attempts = 0
    while true do
        local ok, err = mover.move_to(x, y, z, dig)
        if ok then
            return ok
        end

        local action = fueler.handle_movement_result(ok, err, ctx)

        if action == "retry" then
            goto continue
        end

        attempts = attempts + 1
        if attempts > retries then
            return nil, errors.BLOCKED
        end

        ::continue::
    end
end

function M.move_forward(ctx)
    local retries = (ctx and ctx.retries) or 5

    local attempts = 0
    while true do
        local ok, err = mover.move_forward()
        if ok then
            return ok
        end

        local action = fueler.handle_movement_result(ok, err, ctx)

        if action ~= "retry" then
            break
        end

        attempts = attempts + 1
        if attempts > retries then
            return nil, errors.BLOCKED
        end
    end
end

function M.move_back(ctx)
    local retries = (ctx and ctx.retries) or 5

    local attempts = 0
    while true do
        local ok, err = mover.move_back()
        if ok then
            return ok
        end

        local action = fueler.handle_movement_result(ok, err, ctx)

        if action ~= "retry" then
            break
        end

        attempts = attempts + 1
        if attempts > retries then
            return nil, errors.BLOCKED
        end
    end
end

function M.move_up(ctx)
    local retries = (ctx and ctx.retries) or 5

    local attempts = 0
    while true do
        local ok, err = mover.move_up()
        if ok then
            return ok
        end

        local action = fueler.handle_movement_result(ok, err, ctx)

        if action ~= "retry" then
            break
        end

        attempts = attempts + 1
        if attempts > retries then
            return nil, errors.BLOCKED
        end
    end
end

function M.move_down(ctx)
    local retries = (ctx and ctx.retries) or 5

    local attempts = 0
    while true do
        local ok, err = mover.move_down()
        if ok then
            return ok
        end

        attempts = attempts + 1
        if attempts > retries then
            return nil, errors.BLOCKED
        end

        local action = fueler.handle_movement_result(ok, err, ctx)

        if action ~= "retry" then
            break
        end
    end
end

M.determine_orientation   = mover.determine_orientation
M.opposite_of             = mover.opposite_orientation_of
M.turn_to_direction       = mover.turn_to_direction

M.turn_left               = mover.turn_left
M.turn_right              = mover.turn_right

M.get_current_coordinates = locator.get_current_coordinates

return M
