local core = require("wireless._internal.core")

local router = {
    _handlers = {},
    _allowed  = nil,
}

--- Register a handler for a protocol + operation.
--- op can be exact (e.g., "resupply:request") or "*" for catch-all on that proto.
function router.register_handler(protocol, operation, handler)
    assert(type(protocol) == "string" and type(operation) == "string" and type(handler) == "function", "bad args")
    local by_proto = router._handlers[protocol]
    if not by_proto then
        by_proto = {}; router._handlers[protocol] = by_proto
    end
    local list = by_proto[operation]
    if not list then
        list = {}; by_proto[operation] = list
    end
    table.insert(list, handler)
end

--- Remove a previously registered handler (no-op if missing).
function router.unregister_handler(protocol, operation, handler)
    local by_protocol = router._handlers[protocol]; if not by_protocol then return end
    local list = by_protocol[operation]; if not list then return end
    for i, h in ipairs(list) do
        if h == handler then
            table.remove(list, i); break
        end
    end
end

--- Restrict dispatch to these protocols. Pass nil to clear.
function router.set_allowed_protocols(list)
    if list == nil then
        router._allowed = nil; return
    end
    local set = {}
    for _, p in ipairs(list) do set[p] = true end
    router._allowed = set
end

local function is_allowed(proto)
    local a = router._allowed
    return (a == nil) or a[proto] == true
end

local function dispatch(sender, msg, protocol)
    local by_proto = router._handlers[protocol]; if not by_proto then return false end
    local handled = false

    local function run(list)
        if not list then return end
        for _, handler in ipairs(list) do
            local ok, res = pcall(handler, sender, msg, protocol)
            if ok and res then handled = true end
            -- errors are swallowed; continue to next handler
        end
    end

    run(by_proto[msg.operation]) -- exact op first
    run(by_proto["*"])           -- then wildcard
    return handled
end

--- Process a single message (optional timeout in seconds). Returns true if any handler handled it.
function router.step(timeout)
    local sender, msg, proto = core.receive(timeout)
    if not sender then return false end
    if not is_allowed(proto) then return false end
    if type(msg) ~= "table" or type(msg.operation) ~= "string" then return false end
    return dispatch(sender, msg, proto)
end

--- Run forever, receiving and dispatching messages.
function router.loop()
    while true do router.step() end
end

return router
