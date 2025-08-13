local rpc = require("wireless._internal.rpc")

local pickup = {}

function pickup.request(receiver, pickup_position, what)
    local ok, err = rpc.call(receiver, "pickup:request", {
        position = pickup_position,
        what = what,
    })

    -- TODO: Handle errors better.

    return ok, err
end

function pickup.dispatch(receiver, pickup_position)
    local ok, err = rpc.call(receiver, "pickup:dispatch", pickup_position)

    -- TODO: Handle errors better.

    return ok, err
end

return pickup
