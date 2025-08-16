local core = require("wireless._internal.core")

local registry = {
    operations = {
        register = "registry:register",
        accepted = "registry:accepted",
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

    local attempts = 5

    for i = 1, attempts do
        core.send(manager_id, payload, core.protocols.registry)

        local message = core.await_response(registry.operations.accepted, 5)

        if message then
            break
        end

        if i < attempts then
            sleep(1)
        end
    end
end

function registry.accept(receiver)
    local payload = core.create_payload(registry.operations.accepted)
    core.send(receiver, payload, core.protocols.registry)
end

return registry
