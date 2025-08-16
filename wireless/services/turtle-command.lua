local core = require("wireless._internal.core")

local commands = {
    operations = {
        pause = "commands:pause",
        resume = "commands:resume",
        kill = "commands:kill",
        nudge_task = "commands:nudge_task",
    }
}

function commands.pause_turtle(receiver)
    local payload = core.create_payload(commands.operations.pause)
    core.send(receiver, payload, core.protocols.turtle_commands)
end

function commands.resume_turtle(receiver)
    local payload = core.create_payload(commands.operations.resume)
    core.send(receiver, payload, core.protocols.turtle_commands)
end

function commands.kill_turtle(receiver)
    local payload = core.create_payload(commands.operations.kill)
    core.send(receiver, payload, core.protocols.turtle_commands)
end

function commands.nudge_task(receiver, job_id, amount)
    local data = {
        job_id = job_id,
        amount = amount,
    }
    local payload = core.create_payload(commands.operations.nudge_task, data)

    core.send(receiver, payload, core.protocols.turtle_commands)
end

return commands
