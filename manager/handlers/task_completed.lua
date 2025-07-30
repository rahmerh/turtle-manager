local turtle_store = require("turtle_store")

return function(sender, _)
    local turtle = turtle_store.get(sender)
    turtle.status = "Idle"
    turtle_store.upsert(sender, turtle)
end
