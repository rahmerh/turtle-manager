local turtle_store = require("turtle_store")
local wireless = require("wireless")
local display = require("display")

local printer = require("lib.printer")
local time = require("lib.time")

local handlers = {
    dispatch_pickup = require("handlers.dispatch_pickup"),
    dispatch_resupply = require("handlers.dispatch_resupply"),
}

printer.print_info("Booting manager #" .. os.getComputerID())

wireless.open()
wireless.discovery.host("manager")

wireless.router.register_handler(wireless.protocols.telemetry, "heartbeat:beat", function(sender, msg)
    local turtle = turtle_store.get(sender)

    if not turtle then return false end

    local patched = turtle_store.patch(sender, {
        last_seen = time.epoch_in_seconds(),
        status    = msg.status,
        metadata  = msg.data or turtle.metadata,
    })

    return true
end)

wireless.router.register_handler(wireless.protocols.rpc, "registry:register", function(sender, m)
    wireless.ack(sender, m)

    local data = {
        role = m.data.role,
    }

    turtle_store.upsert(sender, data)

    printer.print_info("New turtle registered: #" .. sender .. " '" .. data.role .. "'")

    return true
end)

wireless.router.register_handler(wireless.protocols.rpc, "pickup:request", handlers.dispatch_pickup)
wireless.router.register_handler(wireless.protocols.rpc, "resupply:request", handlers.dispatch_resupply)

local function render_display()
    while true do
        display.render()
        sleep(1)
    end
end

local function mark_stale()
    while true do
        local turtles = turtle_store.list()
        local now = time.epoch_in_seconds()

        for k, v in pairs(turtles) do
            if now - v.last_seen >= 10 then
                local patched = turtle_store.patch(k, {
                    metadata = {
                        status = "Offline"
                    }
                })
            elseif now - v.last_seen >= 5 then
                local patched = turtle_store.patch(k, {
                    metadata = {
                        status = "Stale"
                    }
                })
            end
        end

        sleep(1)
    end
end

printer.print_success("Manager online.")

parallel.waitForAny(wireless.router.loop, render_display, mark_stale)
