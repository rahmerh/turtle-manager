local mover = require("shared.mover")
local fueler = require("shared.fueler")
local errors = require("shared.errors")
local printer = require("shared.printer")
local inventory = require("shared.inventory")

local function is_turtle(info)
    return info.name == "computercraft:turtle_advanced" or info.name == "computercraft:turtle_normal"
end

return function(task, config)
    printer.print_info("Resupplying turtle at " ..
        task.data.turtle_pos.x .. " " ..
        task.data.turtle_pos.y .. " " ..
        task.data.turtle_pos.z)

    local arrived_at_supply, arrived_at_supply_err = mover.move_to(
        config.supply_chest_pos.x,
        config.supply_chest_pos.y + 1,
        config.supply_chest_pos.z)
    while not arrived_at_supply and arrived_at_supply_err == errors.NO_FUEL do
        fueler.refuel_from_inventory()
        arrived_at_supply, arrived_at_supply_err = mover.move_to(
            config.supply_chest_pos.x,
            config.supply_chest_pos.y + 1,
            config.supply_chest_pos.z)
    end

    turtle.select(2)

    for item, amount in pairs(task.data.desired) do
        inventory.pull_items_from_down(item, amount)
    end

    local turtle_pos = task.data.turtle_pos

    -- +1 to make sure we're on top of the turtle to resupply
    local arrived, err = mover.move_to(turtle_pos.x, turtle_pos.y + 1, turtle_pos.z)
    while not arrived and err == errors.NO_FUEL do
        fueler.refuel_from_inventory()
        arrived, err = mover.move_to(turtle_pos.x, turtle_pos.y + 1, turtle_pos.z)
    end

    local _, info = turtle.inspectDown()
    if is_turtle(info) then
        turtle.select(2)
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
