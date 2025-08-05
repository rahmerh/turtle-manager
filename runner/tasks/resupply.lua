local movement = require("movement")
local wireless = require("wireless")

local errors = require("lib.errors")
local printer = require("lib.printer")
local inventory = require("lib.inventory")

local function is_turtle(info)
    return info.name == "computercraft:turtle_advanced" or info.name == "computercraft:turtle_normal"
end

return function(task, config, movement_context)
    printer.print_info(("[%s] Resupplying turtle at " ..
        task.data.target.x .. " " ..
        task.data.target.y .. " " ..
        task.data.target.z):format(task.data.job_id))

    local arrived, arrived_err = movement.move_to(
        config.supply_chest_pos.x,
        config.supply_chest_pos.y + 1,
        config.supply_chest_pos.z,
        movement_context)
    if not arrived and arrived_err then
        return arrived, arrived_err
    end

    turtle.select(2)

    local filled_slots = {}
    for item, amount in pairs(task.data.desired) do
        local filled_slot = inventory.pull_items_from_down(item, amount)
        table.insert(filled_slots, filled_slot)
    end

    -- +1 to make sure we're on top of the turtle to resupply
    movement.move_to(task.data.target.x, task.data.target.y + 1, task.data.target.z)

    wireless.resupply.runner_arrived(task.data.requester, task.job_id)
    local ok, err = wireless.resupply.await_ready(task.job_id)

    if not ok then
        printer.print_error(err)
        movement.move_to(
            config.unloading_chest_pos.x,
            config.unloading_chest_pos.y + 1,
            config.unloading_chest_pos.z,
            movement_context)

        inventory.drop_slots(2, 16, "down")
        return
    end

    local _, info = turtle.inspectDown()
    if is_turtle(info) then
        for _, slot in ipairs(filled_slots) do
            turtle.select(slot)
            turtle.dropDown()
        end
    else
        return nil, errors.NO_INVENTORY_DOWN
    end

    turtle.select(1)

    wireless.resupply.signal_done(task.data.requester, task.job_id)

    movement.move_to(
        config.unloading_chest_pos.x,
        config.unloading_chest_pos.y + 1,
        config.unloading_chest_pos.z,
        movement_context)

    inventory.drop_slots(2, 16, "down")
end
