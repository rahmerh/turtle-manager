local core = require("wireless._internal.core")

return {
    protocols = core.protocols,
    open = core.open,
    router = require("wireless.router"),
    registry = require("wireless.services.registry"),
    heartbeat = require("wireless.services.heartbeat"),
    discovery = require("wireless.services.discovery"),
    completed = require("wireless.services.job-completed"),
    turtle_commands = require("wireless.services.turtle-command"),
    pickup = require("wireless.services.pickup"),
    resupply = require("wireless.services.resupply"),
    fluid_fill = require("wireless.services.fluid-fill"),
    settings = require("wireless.services.settings"),
}
