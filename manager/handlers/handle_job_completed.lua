local string_util = require("lib.string_util")

return function(sender, msg, turtle_store)
    if msg.job_type == "quarry" then
        -- TODO: Auto pickup
        -- local id = dispatch_utils.find_least_queued(runners, sender)
        local updated = turtle_store:update(sender, {
            ["metadata.status"] = "Completed",
            ["metadata.current_location"] = msg.coordinates,
        })

        return updated
    elseif msg.job_type == "pickup" and string_util.starts_with(msg.what, "turtle") then
        local id = string_util.split_by(msg.what, ":")[2]

        turtle_store:delete(tonumber(id))

        return tonumber(id)
    end
end
