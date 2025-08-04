local turtle_store = require("turtle_store")
local wireless = require("wireless")

local printer = require("shared.printer")
local errors = require("shared.errors")
local dispatch_utils = require("dispatch_helpers")

return function(sender, msg)
    wireless.ack(sender, msg)

    local runners = turtle_store.get_by_role("runner")
    if not runners and next(runners) == nil then
        return nil, errors.wireless.NO_AVAILABLE_RUNNERS
    end

    local id = dispatch_utils.find_least_queued(runners, sender)

    if not id then
        return nil, errors.wireless.NO_AVAILABLE_RUNNERS
    end

    local payload = {
        target = msg.data,
        job_id = msg.id,
    }

    local ok, err = wireless.pickup.dispatch(id, payload)

    if not ok then
        printer.print_warning(err)
        return nil, errors.wireless.COULD_NOT_ASSIGN
    end

    return true
end
