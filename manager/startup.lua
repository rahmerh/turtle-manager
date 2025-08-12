local turtle_store = require("turtle_store")
local wireless = require("wireless")
local Display = require("display")

local printer = require("lib.printer")
local time = require("lib.time")

local handlers = {
    dispatch_pickup = require("handlers.dispatch_pickup"),
    dispatch_resupply = require("handlers.dispatch_resupply"),
    handle_job_completed = require("handlers.handle_job_completed")
}

printer.print_info("Booting manager #" .. os.getComputerID())

wireless.open()
wireless.discovery.host("manager")

local monitor = peripheral.find("monitor")
local display
if monitor then
    display = Display:new(monitor, wireless)

    -- Add everything from the store to the display
    local turtles = turtle_store.list()
    for id, turtle in pairs(turtles) do
        display:add_or_update_turtle(id, turtle)
    end
end

wireless.router.register_handler(wireless.protocols.telemetry, "heartbeat:beat", function(sender, msg)
    local turtle = turtle_store.get(sender)

    if not turtle then return false end

    local patched = turtle_store.update(sender, {
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
        metadata = m.data.metadata
    }

    turtle_store.upsert(sender, data)

    printer.print_info("New turtle registered: #" .. sender .. " '" .. data.role .. "'")

    return true
end)

wireless.router.register_handler(wireless.protocols.rpc, "pickup:request", handlers.dispatch_pickup)
wireless.router.register_handler(wireless.protocols.rpc, "resupply:request", handlers.dispatch_resupply)

wireless.router.register_handler(wireless.protocols.rpc, "job:completed", function(sender, msg)
    local turtle = handlers.handle_job_completed(sender, msg)

    if display then
        display:add_or_update_turtle(sender, turtle)
    end
end)

local function mark_stale()
    while true do
        local turtles = turtle_store.list()
        local now = time.epoch_in_seconds()

        for k, v in pairs(turtles) do
            if v.metadata and (v.metadata.status == "Completed" or v.metadata.status == "Offline") then
                goto continue
            end

            if not v.last_seen or now - v.last_seen >= 15 then
                local updated = turtle_store.set_status(k, "Offline")
                display:add_or_update_turtle(k, updated)
            elseif now - v.last_seen >= 2 then
                local updated = turtle_store.set_status(k, "Stale")
                display:add_or_update_turtle(k, updated)
            end

            ::continue::
        end

        sleep(1)
    end
end

local main_loops = { wireless.router.loop, mark_stale }

if display then
    table.insert(main_loops, function() display:loop() end)
    table.insert(main_loops, function() display.task_runner:loop() end)
end

printer.print_success("Manager online.")

parallel.waitForAny(table.unpack(main_loops))
