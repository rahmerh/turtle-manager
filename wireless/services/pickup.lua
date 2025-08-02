local rpc = require("wireless._internal.rpc")

local pickup = {}

function pickup.request(receiver, chest_position)
    local ok, err = rpc.call(receiver, "pickup:request", chest_position)

    -- TODO: Handle errors better.

    return ok, err
end

function pickup.dispatch(receiver, chest_position)
    local ok, err = rpc.call(receiver, "pickup:dispatch", chest_position)

    -- TODO: Handle errors better.

    return ok, err
end

return pickup
