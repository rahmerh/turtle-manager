local wireless = require("wireless")

local errors = require("lib.errors")
local dispatch_utils = require("dispatch_helpers")

return function(sender, msg, turtle_store)
    local runners = turtle_store:get_by_role("runner")

    if not runners or next(runners) == nil then
        return nil, errors.wireless.NO_AVAILABLE_RUNNERS
    end

    while next(runners) do
        local id = dispatch_utils.find_least_queued(runners, sender)
        if not id then break end

        wireless.resupply.assign(id, msg.data.target, msg.data.manifest, sender)
        local accepted_msg = wireless.resupply.await_accepted()

        if accepted_msg and accepted_msg._sender == id then
            return true
        end

        runners[id] = nil
    end

    return nil, errors.wireless.COULD_NOT_ASSIGN
end
