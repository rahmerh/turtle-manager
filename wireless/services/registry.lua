local core = require("wireless._internal.core")

local registry = {
    operations = {
        register = "registry:register"
    }
}

--- Register this turtle with a manager.
--- @param manager_id integer
--- @param role string              -- e.g. "quarry", "runner", "manager"
--- @return true|nil, string?       -- true or nil,"no_ack"
function registry.announce_at(manager_id, role, metadata)
    local data = {
        role = role,
        metadata = metadata
    }
    local payload = core.create_payload(registry.operations.register, data)

    core.send(manager_id, payload, core.protocols.registry)
end

return registry
