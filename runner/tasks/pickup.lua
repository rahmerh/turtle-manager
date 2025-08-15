local movement = require("movement")

local task_stages = require("task_stages")

local printer = require("lib.printer")

return function(task, config, movement_context, report_progress)
    if not task.stage then
        printer.print_info(("[%s] Picking up %s at %d %d %d"):format(
            task.job_id,
            task.what,
            task.target.x,
            task.target.y,
            task.target.z))

        report_progress(task.job_id, task_stages.to_target, true)
    else
        printer.print_info(("[%s] Resuming pickup task"):format(task.job_id))
    end

    if task.stage == task_stages.to_target then
        local arrived, arrived_err = movement.move_to(
            task.target.x,
            task.target.y + 1, -- Move above it.
            task.target.z,
            movement_context)

        if not arrived and arrived_err then
            return arrived, arrived_err
        end

        -- Pick up chest + it's contents
        turtle.digDown()
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
