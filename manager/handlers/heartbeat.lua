local turtle_store = require("turtle_store")
local wireless = require("wireless")
local display = require("display")
local utils = require("utils")

return function(sender, msg)
    local turtle = turtle_store.get(sender)
    if not turtle then
        wireless.kill(sender)
        return
    end

    turtle.last_seen = utils.epoch_in_seconds()
    turtle.status = msg.status

    if turtle.role == "quarry" then
        turtle.current_layer = msg.current_layer
        turtle.total_layers = msg.total_layers
        display.add_or_update_block(sender, display.quarry_lines(turtle))
    elseif turtle.role == "runner" then
        display.add_or_update_block(sender, display.runner_lines(turtle))
    end

    turtle_store.upsert(sender, turtle)
end
