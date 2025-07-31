local mover = require("mover")
local fueler = require("fueler")
local errors = require("errors")
local printer = require("printer")

return function(task, config)
    fueler.refuel_from_inventory()

    printer.print_info("Picking up chest  at " .. task.data.x .. " " .. task.data.y .. " " .. task.data.z)

    local arrived, err = mover.move_to(task.data.x, task.data.y, task.data.z)

    while not arrived and err == errors.NO_FUEL do
        fueler.refuel_from_inventory()
        arrived, err = mover.move_to(task.data.x, task.data.y, task.data.z)
    end

    -- Pick up chest + it's contents
    turtle.digDown()

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

    -- Drop inventory
    for i = 2, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.count > 0 then
            turtle.select(i)
            turtle.dropDown()
        end
    end
    turtle.select(1)
end
