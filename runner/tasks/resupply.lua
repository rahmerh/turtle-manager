local movement = require("movement")
local wireless = require("wireless")

local task_stages = require("task_stages")

local printer = require("lib.printer")
local inventory = require("lib.inventory")

return function(task, config, movement_context, report_progress)
    local filled_slots = {}

    if not task.stage then
        printer.print_info(("[%s] Resupplying turtle at " ..
            task.target.x .. " " ..
            task.target.y .. " " ..
            task.target.z):format(task.job_id))

        report_progress(task.job_id, task_stages.to_supply, true)

        local arrived, arrived_err = movement.move_to(
            config.supply_chest_pos.x,
            config.supply_chest_pos.y + 1,
            config.supply_chest_pos.z,
            movement_context)

        if not arrived and arrived_err then
            return arrived, arrived_err
        end

        turtle.select(2)

        -- TODO: Handle if too many items requested
        for item, amount in pairs(task.desired) do
            local filled_slot = inventory.pull_items_from_down(item, amount)
            table.insert(filled_slots, filled_slot)
        end

        report_progress(task.job_id, task_stages.to_target, true)
    else
        printer.print_info(("[%s] Resuming resupply task"):format(task.job_id))
    end

    if task.stage == task_stages.to_target then
        movement.move_to(task.target.x, task.target.y + 1, task.target.z, movement_context)

        wireless.resupply.signal_arrived(task.requested_by)

        report_progress(task.job_id, task_stages.resupplying, false)
    end

    if task.stage == task_stages.resupplying then
        for _, slot in ipairs(filled_slots) do
            inventory.drop_slots(slot, slot, "down")
        end

        wireless.resupply.signal_done(task.requested_by)

        report_progress(task.job_id, task_stages.to_unloading, false)
    end

    if task.stage == task_stages.to_unloading then
        local moved_back, moved_back_err = movement.move_to(
            config.unloading_chest_pos.x,
            config.unloading_chest_pos.y + 1,
            config.unloading_chest_pos.z,
            movement_context)

        if not moved_back and moved_back_err then
            return moved_back, moved_back_err
        end
    end
end
