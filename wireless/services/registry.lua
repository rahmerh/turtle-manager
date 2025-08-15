local rpc = require("wireless._internal.rpc")
local core = require("wireless._internal.core")

local errors = require("lib.errors")

local registry = {}

--- Register this turtle with a manager.
--- @param manager_id integer
--- @param role string              -- e.g. "quarry", "runner", "manager"
--- @return true|nil, string?       -- true or nil,"no_ack"
function registry.announce_at(manager_id, role, metadata)
    local id, response = rpc.call(
        manager_id,
        "registry:register",
        core.protocols.rpc,
        { role = role, metadata = metadata })

    if not id then
        return nil, errors.wireless.NO_ACK
    end

    return response.data.settings
end

function registry.respond(receiver, msg_id, settings)
    rpc.respond_on(receiver, msg_id, "registry:register", core.protocols.rpc, { settings = settings })
end

return registry
