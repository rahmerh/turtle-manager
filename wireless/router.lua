local core = require("wireless._internal.core")

local printer = require("lib.printer")

local router = {
    _handlers = {},
}

function router.register_handler(protocol, operation, handler)
    router._handlers[protocol] = router._handlers[protocol] or {}
    local by_protocol = router._handlers[protocol]
    by_protocol[operation] = by_protocol[operation] or {}
    table.insert(by_protocol[operation], handler)
end

local function dispatch(sender, msg, protocol)
    local by_proto = router._handlers[protocol]; if not by_proto then return false end
    local list = by_proto[msg.operation]; if not list then return false end
    local handled = false
    for _, h in ipairs(list) do
        local ok, res, err = pcall(h, sender, msg, protocol)
        if not ok then
            printer.print_error("Handler crash: " .. tostring(res))
        elseif res or err == nil then
            handled = true
        end
    end
    return handled
end

function router.step(timeout)
    local sender, msg, protocol = core.receive(timeout)
    if not sender or type(msg) ~= "table" then
        return false
    end

    if msg.id then core.stash_response(msg) end

    if type(msg.operation) ~= "string" then
        return false
    end

    return dispatch(sender, msg, protocol)
end

function router.loop()
    while true do router.step(5) end
end

return router
