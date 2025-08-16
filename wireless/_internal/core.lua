local time = require("lib.time")
local errors = require("lib.errors")

local _private = {}
local core = {
    protocols = {
        telemetry = "telemetry",
        registry = "registry",
        settings = "settings",
        job = "job",
        pickup = "pickup",
        resupply = "resupply",
        fluid_fill = "fluid_fill",
        turtle_commands = "turtle_commands",
    },
    _inbox = {},
    _listeners = {}
}

math.randomseed((os.epoch("utc") % (2 ^ 31)) + os.getComputerID()); math.random(); math.random()

function _private.next_id()
    return ("%d-%d-%d"):format(os.getComputerID(), os.epoch("utc"), math.random(1, 1e9))
end

function core.create_payload(operation, data)
    return {
        id = _private.next_id(),
        operation = operation,
        data = data,
    }
end

function core.open()
    peripheral.find("modem", rednet.open)
end

function core.send(receiver, payload, protocol)
    rednet.send(receiver, payload, protocol)
end

function core.receive(timeout)
    return rednet.receive(nil, timeout)
end

function core.stash_response(sender, msg)
    if type(msg) == "table" and msg.id then
        msg._sender         = sender
        core._inbox[msg.id] = msg
    end
end

function core.take_response(id)
    local message = core._inbox[id]

    if message then
        core._inbox[id] = nil
    end

    return message
end

function core.await_response(operation, timeout)
    local deadline = time.alive_duration_in_seconds() + timeout

    while true do
        for id, msg in pairs(core._inbox) do
            if type(msg) == "table" and msg.operation == operation then
                core._inbox[id] = nil
                return msg
            end
        end

        if time.alive_duration_in_seconds() >= deadline then
            return nil, errors.wireless.TIMEOUT
        end

        sleep(1)
    end
end

return core
