local core = {}

function core.open() peripheral.find("modem", rednet.open) end

function core.close(side) rednet.close(side) end

function core.send(id, payload, proto) return rednet.send(id, payload, proto) end

function core.receive(timeout) return rednet.receive(nil, timeout) end

return core
