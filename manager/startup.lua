local printer = require("shared.printer")
local wireless = require("wireless")

local handlers = {
    request_pickup = require("handlers.request_pickup"),
    --     request_resupply = require("handlers.request_resupply"),
}

printer.print_success("Manager online.")

wireless.open()
wireless.discovery.host("manager")

wireless.registry.install_on(wireless.router)
wireless.heartbeat.install_on(wireless.router)

wireless.router.loop()
