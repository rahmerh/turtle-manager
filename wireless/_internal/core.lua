local core = {
    protocols = {
        rpc = "rpc",
        notify = "notify",
        telemetry = "telemetry",
    }
}

math.randomseed((os.epoch("utc") % (2 ^ 31)) + os.getComputerID()); math.random(); math.random()
local function next_id()
    return ("%d-%d-%d"):format(os.getComputerID(), os.epoch("utc"), math.random(1, 1e9))
end

function core.open() peripheral.find("modem", rednet.open) end

function core.close(side) rednet.close(side) end

function core.send(receiver, payload, protocol)
    if not core.protocols[protocol] then
        error(("Invalid protocol: %s"):format(protocol))
    end

    local id = next_id()
    payload.id = id

    local ok = rednet.send(receiver, payload, protocol)

    return ok, id
end

function core.receive(timeout)
    return rednet.receive(nil, timeout)
end

return core
