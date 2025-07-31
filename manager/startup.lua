local printer = require("printer")
local display = require("display")
local turtle_store = require("turtle_store")
local wireless = require("wireless")

local handlers = {
    announce = require("announce"),
    heartbeat = require("heartbeat"),
    request_pickup = require("request_pickup"),
    request_resupply = require("request_resupply"),
    task_completed = require("task_completed")
}

printer.print_success("Manager online.")

while true do
    display.render()

    local sender, msg, protocol = wireless.receive_any()
    if msg and handlers[protocol] then
        handlers[protocol](sender, msg)
    elseif msg then
        printer.print_warning("Unhandled protocol: " .. tostring(protocol))
    end

    turtle_store.detect_stale()
end
