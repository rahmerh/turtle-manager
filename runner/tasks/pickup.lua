local locator = require("locator")
local mover = require("mover")

return function(task)
    local current_pos = locator.get_pos()

    mover.move_to(task.pos.x, task.pos.y, task.pos.z)

    -- Pick up chest + it's contents
    turtle.digDown()

    mover.move_to(current_pos.x, current_pos.y, current_pos.z)
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
