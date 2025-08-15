local errors = require("lib.errors")

local core = {
    protocols = {
        rpc = "rpc",
        notify = "notify",
        ack = "ack",
        telemetry = "telemetry",
    },
    _inbox = {}
}

local _private = {}

math.randomseed((os.epoch("utc") % (2 ^ 31)) + os.getComputerID()); math.random(); math.random()

function _private.next_id()
    return ("%d-%d-%d"):format(os.getComputerID(), os.epoch("utc"), math.random(1, 1e9))
end

function core.open()
    peripheral.find("modem", rednet.open)
end

function core.close(side)
    rednet.close(side)
end

function core.send(receiver, payload, protocol)
    payload.id = payload.id or _private.next_id()
    local ok = rednet.send(receiver, payload, protocol)
    return ok, payload.id
end

function core.receive(timeout)
    return rednet.receive(nil, timeout)
end

function core.stash_response(msg)
    print("stash")
    if type(msg) == "table" and msg.id then
        core._inbox[msg.id] = msg
    end
end

function core.take_response(id)
    print("read")
    local m = core._inbox[id]; if m then core._inbox[id] = nil end; return m
end

return core
