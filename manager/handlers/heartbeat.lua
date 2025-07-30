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
    elseif turtle.role == "runner" then
        turtle.queued_tasks = msg.queued_tasks
    end

    local lines = display.status_lines_for(turtle)
    display.add_or_update_block(sender, lines)

    turtle_store.upsert(sender, turtle)
end
