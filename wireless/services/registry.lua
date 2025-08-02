local rpc = require("wireless._internal.rpc")

local errors = require("shared.errors")

local registry = {}

--- Register this turtle with a manager.
--- @param manager_id integer
--- @param role string              -- e.g. "quarry", "runner", "manager"
--- @return true|nil, string?       -- true or nil,"no_ack"
function registry.register_self_as(manager_id, role)
    local ok, _ = rpc.call(manager_id, "registry:register", { role = role })
    if not ok then return nil, errors.wireless.NO_ACK end

    return true
end

return registry
