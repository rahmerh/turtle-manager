local movement = require("movement")

local task_stages = require("task_stages")

local printer = require("lib.printer")
local inventory = require("lib.inventory")

return function(task, config, movement_context, report_progress)
    printer.print_info(("[%s] Filling fluid in %d columns."):format(
        task.job_id,
        #task.fluid_columns))

    local arrived, arrived_err = movement.move_to(
        config.supply_chest_pos.x,
        config.supply_chest_pos.y + 1,
        config.supply_chest_pos.z,
        movement_context)
    if not arrived and arrived_err then
        return arrived, arrived_err
    end
    turtle.select(2)

    local amount_of_filler_blocks = #task.fluid_columns * 3

    local filled_slot = inventory.pull_items_from_down("minecraft:cobblestone", amount_of_filler_blocks)

    report_progress(task.job_id, task_stages.to_target, true)

    for _, column in ipairs(task.fluid_columns) do
        movement.move_to(
            column.x,
            column.y,
            column.z,
            movement_context)

        turtle.select(2)
        turtle.placeUp()
    end

    local moved_back, moved_back_err = movement.move_to(
        config.unloading_chest_pos.x,
        config.unloading_chest_pos.y + 1,
        config.unloading_chest_pos.z,
        movement_context)

    if not moved_back and moved_back_err then
        return moved_back, moved_back_err
    end
end
