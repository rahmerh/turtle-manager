local core = require("wireless._internal.core")

local printer = require("lib.printer")

local router = {
    _handlers = {},
    _allowed  = nil,
}

--- Register a handler for a protocol + operation.
function router.register_handler(protocol, operation, handler)
    assert(type(protocol) == "string" and type(operation) == "string" and type(handler) == "function", "bad args")
    local by_protocol = router._handlers[protocol]

    if not by_protocol then
        by_protocol = {}; router._handlers[protocol] = by_protocol
    end

    local list = by_protocol[operation]
    if not list then
        list = {}; by_protocol[operation] = list
    end

    table.insert(list, handler)
end

--- Remove a previously registered handler.
function router.unregister_handler(protocol, operation, handler)
    local by_protocol = router._handlers[protocol]; if not by_protocol then return end
    local list = by_protocol[operation]; if not list then return end
    for i, h in ipairs(list) do
        if h == handler then
            table.remove(list, i); break
        end
    end
end

local function dispatch(sender, msg, protocol)
    local by_proto = router._handlers[protocol]; if not by_proto then return false end
    local handled = false

    local function run(list)
        if not list then return end
        for _, handler in ipairs(list) do
            local ok, result, err = pcall(handler, sender, msg, protocol)

            if not ok then
                printer.print_error("Handler crash: " .. tostring(result))
            elseif result == nil and err ~= nil then
                printer.print_error("Handler error: " .. tostring(err))
            elseif result then
                handled = true
            end
        end
    end

    run(by_proto[msg.operation])
    return handled
end

--- Process a single message (optional timeout in seconds). Returns true if any handler handled it.
function router.step(timeout)
    local sender, msg, protocol = core.receive(timeout)

    if not sender then
        return false
    end

    if type(msg) ~= "table" and type(msg.operation) ~= "string" then
        return false
    end

    return dispatch(sender, msg, protocol)
end

--- Run forever, receiving and dispatching messages.
function router.loop()
    while true do router.step(5) end
end

return router
