local rpc = require("wireless._internal.rpc")
local core = require("wireless._internal.core")

local commands = {}

function commands.pause_turtle(receiver)
    return rpc.call(receiver, "command:pause")
end

function commands.resume_turtle(receiver)
    return rpc.call(receiver, "command:resume")
end

function commands.reboot_turtle(receiver)
    return rpc.call(receiver, "command:reboot")
end

function commands.confirm_kill(receiver, id, coordinates)
    core.send(receiver, {
            operation = "command:kill",
            coordinates = coordinates
        },
        "rpc",
        id)
end

function commands.kill_turtle(receiver)
    local message_id = core.send(receiver, { operation = "command:kill", }, "rpc")

    local ok, _, msg, _ = core.await_response_on(message_id)

    if not ok or not msg then
        return
    end

    return msg.coordinates
end

function commands.nudge_task(receiver, job_id, amount)
    return rpc.call(receiver, "command:nudge_task", {
        job_id = job_id,
        amount = amount
    })
end

return commands
