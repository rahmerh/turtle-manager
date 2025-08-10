local wireless      = require("wireless")

local queue         = require("lib.queue")
local printer       = require("lib.printer")

local WAKE_EVENT    = "taskrunner:wake"

local task_runner   = {
    tasks = {
        pause = "pause",
        resume = "resume",
        recover = "recover"
    },
}
task_runner.__index = task_runner

local handlers      = {
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
        local coordinates = wireless.turtle_commands.kill_turtle(data.id)

        local manager_id = wireless.discovery.find("manager")

        wireless.pickup.request(manager_id, coordinates)

        return true
    end
}

function task_runner:new(db_path)
    return setmetatable({
        task_queue = queue.new(db_path or "display_tasks.db"),
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
            local fn = handlers[item.task]
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
