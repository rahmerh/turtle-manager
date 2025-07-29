local turtle_store = require("turtle_store")
local display = require("display")
local utils = require("utils")
local wireless = require("wireless")

return function(sender, msg)
    wireless.send(sender, "ack", "announce")

    local turtle = {
        id = sender,
        role = msg,
        last_seen = utils.epoch_in_seconds(),
        status = "New",
        current_layer = 0,
        total_layers = 0
    }

    turtle_store.upsert(sender, turtle)
end
