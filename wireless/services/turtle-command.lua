local core = require("wireless._internal.core")

local commands = {}

function commands.pause_turtle(receiver)
end

function commands.resume_turtle(receiver)
end

function commands.reboot_turtle(receiver)
end

function commands.kill_turtle(receiver)
end

function commands.confirm_kill(receiver, id, coordinates)
end

function commands.nudge_task(receiver, job_id, amount)
end

return commands
