local wireless      = require("wireless")

local queue         = require("lib.queue")
local printer       = require("lib.printer")

local WAKE_EVENT    = "taskrunner:wake"

local task_runner   = {
    tasks = {
        pause = "pause",
        resume = "resume",
        recover = "recover",
        nudge_task = "nudge_task",
    },
}
task_runner.__index = task_runner

function task_runner:new(notifier)
    local handlers = {
        pause = function(data)
            local ok, err = wireless.turtle_commands.pause_turtle(data.id)
            if not ok then error(err or "pause failed") end
            return true
        end,
        resume = function(data)
            local ok, err = wireless.turtle_commands.resume_turtle(data.id)
            if not ok then error(err or "resume failed") end
            return true
        end,
        recover = function(data)
            local coordinates
            if data.offline_turtle then
                coordinates = data.offline_turtle.metadata.current_location
            else
                coordinates = wireless.turtle_commands.kill_turtle(data.id)
            end

            local manager_id = wireless.discovery.find("manager")

            wireless.pickup.request(manager_id, coordinates, "turtle:" .. data.id)

            notifier:add_notification(("Recovering turtle #%d..."):format(data.id), 10)

            return true
        end,
        nudge_task = function(data)
            wireless.turtle_commands.nudge_task(data.id, data.job_id, data.amount)
        end
    }
    return setmetatable({
        task_queue = queue.new("display_tasks.db"),
        notifier = notifier,
        handlers = handlers
    }, self)
end

function task_runner:add_task(task, data)
    if not self.tasks[task] then
        error("Invalid task '" .. tostring(task) .. "'")
    end

    self.task_queue:enqueue({ task = task, data = data or {} })
    os.queueEvent(WAKE_EVENT)
end

function task_runner:loop()
    while true do
        local item = self.task_queue:peek()
        if not item then
            os.pullEvent(WAKE_EVENT)
        else
            local fn = self.handlers[item.task]
            if not fn then
                printer.print_error("Invalid task: " .. item.task)
                self.task_queue:ack()
            else
                local ok, res_or_err = xpcall(function() return fn(item.data) end, debug.traceback)

                if ok then
                    self.task_queue:ack()
                else
                    printer.print_error(("Task '%s' failed: %s"):format(item.task, res_or_err))
                    sleep(1)
                end
            end
        end
    end
end

return task_runner
