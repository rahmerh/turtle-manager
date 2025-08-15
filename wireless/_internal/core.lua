local errors = require("lib.errors")

local core = {
    protocols = {
        rpc = "rpc",
        notify = "notify",
        ack = "ack",
        telemetry = "telemetry",
    }
}

math.randomseed((os.epoch("utc") % (2 ^ 31)) + os.getComputerID()); math.random(); math.random()

local function next_id()
    return ("%d-%d-%d"):format(os.getComputerID(), os.epoch("utc"), math.random(1, 1e9))
end

function core.open()
    peripheral.find("modem", rednet.open)
end

function core.close(side)
    rednet.close(side)
end

function core.send(receiver, payload, protocol)
    if not core.protocols[protocol] then
        error(("Invalid protocol: %s"):format(protocol))
    end

    if not payload.id then
        local id = next_id()
        payload.id = id
    end

    local ok = rednet.send(receiver, payload, protocol)

    return ok, payload.id
end

function core.receive(timeout)
    return rednet.receive(nil, timeout)
end

function core.wait_for_response_on(msg_id, timeout)
    local timer = os.startTimer(timeout)

    while true do
        local ev, a1, a2, a3 = os.pullEvent()

        if ev == "rednet_message" then
            local _, msg, _ = a1, a2, a3
            if type(msg) == "table" and msg.id ~= nil and msg.id == msg_id then
                return msg
            end
        elseif ev == "timer" and a1 == timer then
            return nil, errors.wireless.TIMEOUT
        end
    end
end

function core.wait_for_response_on_operation(operation, timeout)
    local timer = os.startTimer(timeout)

    while true do
        local ev, a1, a2, a3 = os.pullEvent()

        if ev == "rednet_message" then
            local sender, msg, _ = a1, a2, a3
            if type(msg) == "table" and
                msg.operation ~= nil and
                msg.operation == operation then
                return sender, msg
            end
        elseif ev == "timer" and a1 == timer then
            return nil, errors.wireless.TIMEOUT
        end
    end
end

return core
