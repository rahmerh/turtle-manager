local rpc = require("wireless._internal.rpc")
local store = require("wireless._internal.turtle_store")

local errors = require("shared.errors")
local printer = require("shared.printer")

local PROTOCOL = "rpc"

local registry = {}

--- Register this turtle with a manager.
--- @param manager_id integer
--- @param role string              -- e.g. "quarry", "runner", "manager"
--- @return true|nil, string?       -- true or nil,"no_ack"
function registry.register(manager_id, role)
    local ok, _ = rpc.call(manager_id, "registry:register", { role = role })
    if not ok then return nil, errors.wireless.NO_ACK end

    return true
end

--- Helper method to install this registry on the given router
---@param router router to install onto
function registry.install_on(router)
    local function upsert(id, data)
        return store.upsert(id, data)
    end

    -- Client → Manager: registry:register (ACK immediately, then record)
    router.register_handler(PROTOCOL, "registry:register", function(sender, m)
        rpc.ack(sender, m)

        local data = {
            role = m.data.role,
        }

        upsert(sender, data)

        printer.print_info("New turtle registered: #" .. sender .. " '" .. data.role .. "'")

        return true
    end)
end

return registry
