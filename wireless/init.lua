local core = require("wireless._internal.core")
local rpc = require("wireless._internal.rpc")

local protocols = {
    rpc = "rpc",
    telemetry = "telemetry"
}

return {
    protocols = protocols,
    open = core.open,
    ack = rpc.ack,
    router = require("wireless.router"),
    registry = require("wireless.services.registry"),
    heartbeat = require("wireless.services.heartbeat"),
    discovery = require("wireless.services.discovery"),
    completed = require("wireless.services.job-completed"),
    turtle_commands = require("wireless.services.turtle-command"),
    pickup = require("wireless.services.pickup"),
    resupply = require("wireless.services.resupply"),
}
