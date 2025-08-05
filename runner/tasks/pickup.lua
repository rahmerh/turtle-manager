local movement = require("movement")

local printer = require("lib.printer")
local inventory = require("lib.inventory")

return function(task, config, movement_context)
    printer.print_info(("[%s] Picking up chest  at " ..
        task.data.target.x .. " " ..
        task.data.target.y .. " " ..
        task.data.target.z):format(task.data.job_id))

    local arrived, arrived_err = movement.move_to(
        task.data.target.x,
        task.data.target.y,
        task.data.target.z,
        movement_context)

    if not arrived and arrived_err then
        return arrived, arrived_err
    end

    -- Pick up chest + it's contents
    turtle.digDown()

    local moved_back, moved_back_err = movement.move_to(
        config.unloading_chest_pos.x,
        config.unloading_chest_pos.y + 1,
        config.unloading_chest_pos.z,
        movement_context)

    if not moved_back and moved_back_err then
        return moved_back, moved_back_err
    end

    inventory.drop_slots(2, 16, "down")
end
