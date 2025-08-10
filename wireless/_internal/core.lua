local core = {}

math.randomseed((os.epoch("utc") % (2 ^ 31)) + os.getComputerID()); math.random(); math.random()
local function next_id()
    return ("%08x%04x"):format(math.random(0, 0xffffffff), math.random(0, 0xffff))
end

function core.open() peripheral.find("modem", rednet.open) end

function core.close(side) rednet.close(side) end

function core.send(receiver, payload, protocol, id)
    if not id then
        id = next_id()
    end
    payload.id = id

    rednet.send(receiver, payload, protocol)

    return id
end

function core.await_response_on(id, timeout)
    timeout = timeout or 1

    local e, a, b, c = os.pullEvent(("rn:%s"):format(id))
    print("In loop...")
    return true, a, b, c
end

function core.receive(timeout) return rednet.receive(nil, timeout) end

return core
