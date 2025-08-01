local mover = require("movement.mover")
local fueler = require("movement.fueler")

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
            break
        end

        attempts = attempts + 1
        if attempts > retries then
            return nil, "TEMP"
        end
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
            return nil, "TEMP"
        end
    end
end

M.opposite_of = mover.opposite_orientation_of
M.turn_to_direction = mover.turn_to_direction

M.turn_left = mover.turn_left
M.turn_right = mover.turn_right

return M
