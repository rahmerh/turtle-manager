local locator = require("locator")
local mover = require("mover")
local fueler = require("fueler")
local errors = require("errors")

return function(task)
    local current_pos = locator.get_pos()
    fueler.refuel_from_inventory()

    local arrived, err = mover.move_to(task.pos.x, task.pos.y, task.pos.z)

    while not arrived and err == errors.NO_FUEL do
        fueler.refuel_from_inventory()
        arrived, err = mover.move_to(task.pos.x, task.pos.y, task.pos.z)
    end

    -- Pick up chest + it's contents
    turtle.digDown()

    local moved_back, moved_back_err = mover.move_to(current_pos.x, current_pos.y, current_pos.z)
    while not moved_back and moved_back_err == errors.NO_FUEL do
        fueler.refuel_from_inventory()
        moved_back, moved_back_err = mover.move_to(task.pos.x, task.pos.y, task.pos.z)
    end

    -- TODO: Actually configure a dropoff chest
    mover.turn_to_direction("south")

    -- Drop inventory
    for i = 2, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.count > 0 then
            turtle.select(i)
            turtle.drop()
        end
    end
    turtle.select(1)
end
