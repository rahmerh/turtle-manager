local mover = require("mover")
local fueler = require("fueler")
local errors = require("errors")

local function is_turtle(info)
    return info.name == "computercraft:turtle_advanced" or info.name == "computercraft:turtle_normal"
end

return function(task, config)
    fueler.refuel_from_inventory()

    local arrived_at_coal, arrived_at_coal_err = mover.move_to(
        config.coal_chest_pos.x,
        config.coal_chest_pos.y + 1,
        config.coal_chest_pos.z)
    while not arrived_at_coal and arrived_at_coal_err == errors.NO_FUEL do
        fueler.refuel_from_inventory()
        arrived_at_coal, arrived_at_coal_err = mover.move_to(
            config.coal_chest_pos.x,
            config.coal_chest_pos.y + 1,
            config.coal_chest_pos.z)
    end

    turtle.select(2)
    turtle.suckDown()

    -- +1 to make sure we're on top of the turtle to resupply
    local arrived, err = mover.move_to(task.pos.x, task.pos.y + 1, task.pos.z)
    while not arrived and err == errors.NO_FUEL do
        fueler.refuel_from_inventory()
        arrived, err = mover.move_to(task.pos.x, task.pos.y, task.pos.z)
    end

    local ok, info = turtle.inspectDown()

    if not ok then
        -- TODO: Handle error
    end

    if is_turtle(info) then
        turtle.dropDown()
    else
        -- TODO: Handle error
    end
    turtle.select(1)

    local moved_back, moved_back_err = mover.move_to(
        config.unloading_chest_pos.x,
        config.unloading_chest_pos.y + 1,
        config.unloading_chest_pos.z)

    while not moved_back and moved_back_err == errors.NO_FUEL do
        fueler.refuel_from_inventory()
        moved_back, moved_back_err = mover.move_to(
            config.unloading_chest_pos.x,
            config.unloading_chest_pos.y + 1,
            config.unloading_chest_pos.z)
    end
end
