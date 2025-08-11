local turtle_store = require("turtle_store")

local errors = require("lib.errors")

return function(sender, msg)
    local runners = turtle_store.get_by_role("runner")
    if not runners and next(runners) == nil then
        return nil, errors.wireless.NO_AVAILABLE_RUNNERS
    end

    -- TODO: Auto pickup
    -- local id = dispatch_utils.find_least_queued(runners, sender)

    return turtle_store.update(sender, {
        metadata = {
            status           = "Completed",
            current_location = msg.coordinates
        }
    })
end
