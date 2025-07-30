local printer = require("printer")

local wireless = {}

local RETRY_DELAY_IN_SECONDS = 10
if not rednet.isOpen() then
    for _ = 1, 5 do
        for _, side in ipairs(peripheral.getNames()) do
            if peripheral.getType(side) == "modem" then
                rednet.open(side)
                if rednet.isOpen() then
                    break
                end
            end
        end

        if rednet.isOpen() then
            break
        end

        printer.print_warning("No modem found, retrying in " .. RETRY_DELAY_IN_SECONDS .. " seconds.")
        sleep(RETRY_DELAY_IN_SECONDS)
    end

    if not rednet.isOpen() then
        error("No modem found for rednet communication", 0)
    end
end

function wireless.broadcast(message, protocol)
    return rednet.broadcast(message, protocol)
end

function wireless.receive(timeout, protocol)
    local sender, msg, proto = rednet.receive(protocol, timeout)
    if not sender then return nil end
    return sender, msg, proto
end

function wireless.send(receiver, msg, protocol)
    return rednet.send(receiver, msg, protocol)
end

function wireless.heartbeat(receiver, metadata)
    return rednet.send(receiver, metadata, "heartbeat")
end

function wireless.register_new_turtle(role, timeout)
    timeout = timeout or 10

    wireless.broadcast(role, "announce")

    local sender, msg, _ = wireless.receive(timeout, "announce")
    if sender and msg == "ack" then
        return sender
    end

    return nil, "No manager found."
end

function wireless.kill(id)
    wireless.send(id, id, "kill")
end

return wireless
