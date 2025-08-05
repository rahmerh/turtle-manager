local turtle_store = require("turtle_store")
local wireless = require("wireless")
local Display = require("display")

local printer = require("lib.printer")
local time = require("lib.time")

local handlers = {
    dispatch_pickup = require("handlers.dispatch_pickup"),
    dispatch_resupply = require("handlers.dispatch_resupply"),
}

printer.print_info("Booting manager #" .. os.getComputerID())

wireless.open()
wireless.discovery.host("manager")

local monitor = peripheral.find("monitor")
local display
if monitor then
    display = Display:new(monitor)
end

wireless.router.register_handler(wireless.protocols.telemetry, "heartbeat:beat", function(sender, msg)
    local turtle = turtle_store.get(sender)

    if not turtle then return false end

    local patched = turtle_store.patch(sender, {
        last_seen = time.epoch_in_seconds(),
        status    = msg.status,
        metadata  = msg.data or turtle.metadata,
    })

    if display then
        display:add_or_update_turtle(sender, patched)
    end

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

local main_loops = { wireless.router.loop, mark_stale }

if display then
    table.insert(main_loops, function() display:loop() end)
end

printer.print_success("Manager online.")

parallel.waitForAny(table.unpack(main_loops))
