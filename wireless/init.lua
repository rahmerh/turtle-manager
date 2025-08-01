local core = require("wireless._internal.core")
return {
    open = core.open,
    router = require("wireless.router"),
    registry = require("wireless.services.registry"),
    heartbeat = require("wireless.services.heartbeat"),
    discovery = require("wireless.services.discovery"),
}
