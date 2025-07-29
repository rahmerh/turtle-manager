local printer = require("printer")
local display = require("display")
local turtle_store = require("turtle_store")

local handlers = {
    announce = require("announce"),
    heartbeat = require("heartbeat"),
    pickup = require("pickup")
}

printer.print_success("Manager online.")

while true do
    display.render()

    local sender, msg, protocol = rednet.receive(nil, 1)
    if msg and handlers[protocol] then
        handlers[protocol](sender, msg)
    elseif msg then
        printer.print_warning("Unhandled protocol: " .. tostring(protocol))
    end

    turtle_store.purge_stale(30)
end
