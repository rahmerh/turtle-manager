local notify = require("wireless._internal.notify")
local rpc = require("wireless._internal.rpc")
local core = require("wireless._internal.core")

local commands = {}

function commands.pause_turtle(receiver)
    notify.send(receiver, "command:pause", core.protocols.notify)
end

function commands.resume_turtle(receiver)
    notify.send(receiver, "command:resume", core.protocols.notify)
end

function commands.reboot_turtle(receiver)
    notify.send(receiver, "command:reboot", core.protocols.notify)
end

function commands.kill_turtle(receiver)
    local msg_id, coordinates = rpc.call(receiver, "command:kill", core.protocols.rpc)

    if not msg_id or not coordinates then
        return
    end

    return coordinates
end

function commands.confirm_kill(receiver, id, coordinates)
    rpc.respond_on(receiver, id, core.protocols.rpc, coordinates)
end

function commands.nudge_task(receiver, job_id, amount)
    notify.send(receiver, "command:nudge_task", core.protocols.notify, {
        job_id = job_id,
        amount = amount
    })
end

return commands
