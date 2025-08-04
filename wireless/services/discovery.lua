local time = require("lib.time")

local discovery = {}

local PROTOCOL_PREFIX = "discovery"

local function protocol_from_role(role)
    role = string.lower(role)
    if not role:match("^[a-z0-9:_-]+$") then
        error("Bad role: " .. tostring(role))
    end
    return PROTOCOL_PREFIX .. role
end

--- Advertise this computer under a role/name.
--- @param role string   e.g., "manager", "runner", "quarry"
--- @param name string  instance name
function discovery.host(role, name)
    name = name or "default"
    if not role then
        error("Role can't be nil")
    end

    rednet.host(protocol_from_role(role), name)

    return true
end

--- Find a single computer id for role+name
--- @param role string   e.g., "manager", "runner", "quarry"
--- @param name string  instance name
--- @return integer|nil, string?  id or nil,"not_found"
function discovery.find(role, name)
    name = name or "default"
    if not role then
        error("Role can't be nil")
    end

    local deadline = time.alive_duration_in_seconds() + 5

    repeat
        local id = rednet.lookup(protocol_from_role(role), name)
        if id then return id end
        sleep(0.5)
    until time.alive_duration_in_seconds() >= deadline

    return nil, "not_found"
end

return discovery
